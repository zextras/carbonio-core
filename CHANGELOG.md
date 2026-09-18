## [4.6.7](https://github.com/zextras/carbonio-core/compare/4.6.6...4.6.7) (2026-09-18)

### Bug Fixes

* **core:** run tmpfiles while /opt/zextras/conf is still root-owned ([#195](https://github.com/zextras/carbonio-core/issues/195)) ([ce0d6e3](https://github.com/zextras/carbonio-core/commit/ce0d6e3e878efe7dbb91c5e1e097bcca2641d63c))

## [4.6.6](https://github.com/zextras/carbonio-core/compare/4.6.5...4.6.6) (2026-09-17)

### Bug Fixes

* **tmpfiles:** stop making /opt/zextras/common/conf contents group-writable ([#193](https://github.com/zextras/carbonio-core/issues/193)) ([7f9b299](https://github.com/zextras/carbonio-core/commit/7f9b299249c042ccedeb76a92205e35cadfe2547))

## [4.6.5](https://github.com/zextras/carbonio-core/compare/4.6.4...4.6.5) (2026-09-17)

### Bug Fixes

* **configd:** drop seccomp hardening that implicitly re-enables NoNewPrivileges (CO-4222) ([#192](https://github.com/zextras/carbonio-core/issues/192)) ([2e3566e](https://github.com/zextras/carbonio-core/commit/2e3566edb862142828ecc03695101ec165cd3b20))
* **core:** ignore /opt/zextras/data/tmp in needrestart scans (CO-4287) ([#191](https://github.com/zextras/carbonio-core/issues/191)) ([3502fef](https://github.com/zextras/carbonio-core/commit/3502fef34849390236069b99744c6b7cc42adb74))

## [4.6.4](https://github.com/zextras/carbonio-core/compare/4.6.3...4.6.4) (2026-09-17)

### Bug Fixes

* **configd:** never leave lAction held after a failed rewrite (CO-4290) ([#190](https://github.com/zextras/carbonio-core/issues/190)) ([9fa8b81](https://github.com/zextras/carbonio-core/commit/9fa8b814f396ad2ea88d10a89dd6b1ab209c41d6))

## [4.6.3](https://github.com/zextras/carbonio-core/compare/4.6.2...4.6.3) (2026-09-16)

### Bug Fixes

* **syslog:** drop debug priority from auth facility selectors ([#189](https://github.com/zextras/carbonio-core/issues/189)) ([fc1590d](https://github.com/zextras/carbonio-core/commit/fc1590dc3ff9ddb9c9e5443b92e0eb6ed174c4a0)), closes [zextras/carbonio-thirds#237](https://github.com/zextras/carbonio-thirds/issues/237)

## [4.6.2](https://github.com/zextras/carbonio-core/compare/4.6.1...4.6.2) (2026-09-16)

### Bug Fixes

* **core:** re-assert sibling tmpfiles.d fragments in postinst (CO-4269) ([#188](https://github.com/zextras/carbonio-core/issues/188)) ([d92fc14](https://github.com/zextras/carbonio-core/commit/d92fc14d05d021fb5a3a7238a318e2b8e851cbdc))

## [4.6.1](https://github.com/zextras/carbonio-core/compare/4.6.0...4.6.1) (2026-09-16)

### Bug Fixes

* **core:** stop recursive chown of /opt/zextras/conf (CO-4269) ([#186](https://github.com/zextras/carbonio-core/issues/186)) ([6c86d83](https://github.com/zextras/carbonio-core/commit/6c86d83e8b8f8fc5ecfb41f259c83a1f9f64705a))

## [4.6.0](https://github.com/zextras/carbonio-core/compare/4.5.21...4.6.0) (2026-09-10)

### Features

* **CO-4256:** warn about domains still using deprecated Virtual IPs ([#183](https://github.com/zextras/carbonio-core/issues/183)) ([2f45b43](https://github.com/zextras/carbonio-core/commit/2f45b43720bc7074e244989f51257c16b566e002))

## [4.5.21](https://github.com/zextras/carbonio-core/compare/4.5.20...4.5.21) (2026-08-30)

## [4.5.20](https://github.com/zextras/carbonio-core/compare/4.5.19...4.5.20) (2026-08-26)

### Bug Fixes

* **CO-4184:** stop recursive chown of certbot config dir ([21eb5b6](https://github.com/zextras/carbonio-core/commit/21eb5b6e8b6204a8b49e286a13297492107ee4ca))

## [4.5.19](https://github.com/zextras/carbonio-core/compare/4.5.18...4.5.19) (2026-08-17)

## [4.5.18](https://github.com/zextras/carbonio-core/compare/4.5.17...4.5.18) (2026-08-11)

## [4.5.17](https://github.com/zextras/carbonio-core/compare/4.5.16...4.5.17) (2026-07-31)

## [4.5.16](https://github.com/zextras/carbonio-core/compare/4.5.15...4.5.16) (2026-07-27)

## [4.5.15](https://github.com/zextras/carbonio-core/compare/4.5.14...4.5.15) (2026-07-21)

## [4.5.14](https://github.com/zextras/carbonio-core/compare/4.5.13...4.5.14) (2026-07-16)

## [4.5.13](https://github.com/zextras/carbonio-core/compare/4.5.12...4.5.13) (2026-07-13)

## [4.5.12](https://github.com/zextras/carbonio-core/compare/4.5.11...4.5.12) (2026-06-25)

### Bug Fixes

* [CO-3815] core: remove carbonio-openldap run-time dep ([c6755c9](https://github.com/zextras/carbonio-core/commit/c6755c9949753ef9fb12d0a140f7e9086d5cba5e))

## [4.5.11](https://github.com/zextras/carbonio-core/compare/4.5.10...4.5.11) (2026-06-22)

### Bug Fixes

* units: remove unneeded ReadOnlyPaths ([991c1c0](https://github.com/zextras/carbonio-core/commit/991c1c07d6f9257ae439f02eed1bc278df724dfd))

## [4.5.10](https://github.com/zextras/carbonio-core/compare/4.5.9...4.5.10) (2026-06-11)

### Bug Fixes

* bump carbonio-core-utils to v1.0.2 ([0bae17c](https://github.com/zextras/carbonio-core/commit/0bae17ce138208df533874e191fcf8999970e8a6))

## [4.5.9](https://github.com/zextras/carbonio-core/compare/4.5.8...4.5.9) (2026-06-11)

## [4.5.8](https://github.com/zextras/carbonio-core/compare/4.5.7...4.5.8) (2026-06-09)

### Bug Fixes

* **core:** bump carbonio-core-utils to aa2f3c07c2 ([#141](https://github.com/zextras/carbonio-core/issues/141)) ([65ecbe8](https://github.com/zextras/carbonio-core/commit/65ecbe809c21ef3baca5c46aa586ece9d6f7c444))
