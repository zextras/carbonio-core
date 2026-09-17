#
# SPDX-FileCopyrightText: 2021 Synacor, Inc.
#
# SPDX-License-Identifier: GPL-2.0-only
#


import os
import signal
import socket
import SocketServer
import threading
import time

import state

from logmsg import *

# Upper bound for how long a REWRITE client is held on the socket. Must stay
# below the systemd TimeoutStartSec (default 90s) of units that probe us from
# ExecStartPre (carbonio-mailthreat, carbonio-policyd). CO-4290.
REWRITE_TIMEOUT = 60

class ThreadedRequestHandler(SocketServer.BaseRequestHandler):

	def handle(self):

		data = self.request.recv(2048)
		Log.logMsg(5, "Received %s" % data)
		args = data.split()
		if len(args) == 0:
			response = "ERROR UNKNOWN COMMAND"
		elif args[0] == "STATUS":
			response = "SUCCESS ACTIVE"
		elif args[0] == "REWRITE":
			if len(args) < 2:
				response = "ERROR NO SERVICES LISTED"
			else:
				Log.logMsg (5, "LOCK myState.lAction requested")
				state.State.mState.lAction.acquire() # Don't interrupt the rewrite process
				Log.logMsg (5, "LOCK myState.lAction acquired")
				for arg in args[1:]:
					Log.logMsg(3, "Processing rewrite request for %s" % arg)
					state.State.mState.requestedconfig[arg] = arg
				os.kill(os.getpid(),signal.SIGUSR2) # wake up the main thread if it's sleeping
				Log.logMsg (5, "LOCK myState.lAction wait()")
				state.State.mState.lAction.wait(REWRITE_TIMEOUT)
				# Python 2 wait() does not report timeouts; the main loop clears
				# requestedconfig before rewriting, so a still-queued service means
				# we timed out. The request stays queued and runs on the next cycle.
				pending = [arg for arg in args[1:] if arg in state.State.mState.requestedconfig]
				Log.logMsg (5, "LOCK myState.lAction released")
				state.State.mState.lAction.release()
				if pending:
					Log.logMsg(1, "Rewrite request timed out after %ds for %s" % (REWRITE_TIMEOUT, " ".join(pending)))
					response = "ERROR REWRITE TIMEOUT"
				else:
					response = "SUCCESS REWRITES COMPLETE"
		else:
			response = "ERROR UNKNOWN COMMAND"

		Log.logMsg(5, "Sending %s" % response)
		self.request.send(response)

class ThreadedStreamServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):

	allow_reuse_address = True

	def shutdown(self):
		Log.logMsg(5, "Removing socket %s" % self.server_address)

class ThreadedStreamServerIPv6(SocketServer.ThreadingMixIn, SocketServer.TCPServer):

	allow_reuse_address = True
	address_family = socket.AF_INET6

	def shutdown(self):
		Log.logMsg(5, "Removing socket %s" % self.server_address)
