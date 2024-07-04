#!/bin/bash
#
# SPDX-FileCopyrightText: 2023 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only
#

TARGET=$1

if [[ ${TARGET} == '' || ${TARGET} == 'ubuntu-jammy' ]]; then
  docker run --entrypoint=yap -v "$(pwd)/artifacts/ubuntu-jammy:/artifacts" -v "$(pwd)":/tmp/staging registry.dev.zextras.com/jenkins/pacur/ubuntu-22.04:v2 build ubuntu-jammy -c /tmp/staging -s
else
  if [[ ${TARGET} == 'rocky-8' ]]; then
    docker run --entrypoint=yap -v "$(pwd)/artifacts/rocky-8:/artifacts" -v "$(pwd)":/tmp/staging registry.dev.zextras.com/jenkins/pacur/rocky-8:v2 build rocky-8 -c /tmp/staging -s
  fi
fi
