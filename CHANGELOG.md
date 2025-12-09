# Changelog

## [2.2.0] - 09-Dec-2025
### NEED ACTION
- add EMAIL_DKIM_OPER_MODE = v OR s OR sv (s - sign / v - validate)
### Changed
- openDKIM by default use as validate.
- milter_protocol to 6
### Disabled
- old parameter smtp_use_tls

## [2.1.0] - 07-Dec-2025
### Changed
- configured Sieve + ManageSieve

## [2.0.0] - 07-Dec-2025
### NEED ACTION
- migrate /var/vmail/user@domain/user@domain --> /var/vmail/domain/user/Maildir
### Added
- Sieve
- ManageSieve
### Changed
- update version to 2.4+
### Disabled
- opendkim

## [1.2.2] - 12-Dec-2024
### Changed
- Fix master.cf postfix

## [1.2.1] - 12-Dec-2024
### Changed
- Minor fixes

## [1.2.0-r3] - 12-Dec-2024
### Added
- Proxy protocol support
### Changed
- Files master (dovecot's and postfix's) template now 