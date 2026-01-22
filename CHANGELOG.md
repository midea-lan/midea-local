# Changelog

## [6.6.0](https://github.com/midea-lan/midea-local/compare/v6.5.0...v6.6.0) (2026-01-22)


### Features

* **c3:** add water inlet/outlet temperature and current power sensors ([#418](https://github.com/midea-lan/midea-local/issues/418)) ([8cef9f4](https://github.com/midea-lan/midea-local/commit/8cef9f4da6059f90cd0baec9f1ac647d18a1d53b)), closes [#510](https://github.com/midea-lan/midea-local/issues/510)
* **doc:** add contributing guide docs ([#413](https://github.com/midea-lan/midea-local/issues/413)) ([3d7e1e8](https://github.com/midea-lan/midea-local/commit/3d7e1e8881a2ecb56f6a1e73ed7353a51432fd5c))


### Bug Fixes

* **ac:** allow half-degree integer temperatures ([#412](https://github.com/midea-lan/midea-local/issues/412)) ([95ba499](https://github.com/midea-lan/midea-local/commit/95ba499551ce794d5d99ddccef99c34deb5755ba))
* **ac:** refactor to add new binary power format ([#411](https://github.com/midea-lan/midea-local/issues/411)) ([ba39f10](https://github.com/midea-lan/midea-local/commit/ba39f104d8cb33c856fcf8de6a74772e99772736))
* **cd:** updating to inconsistent values and missing F to C conversion ([#420](https://github.com/midea-lan/midea-local/issues/420)) ([7ff2b3f](https://github.com/midea-lan/midea-local/commit/7ff2b3fb583b7fc0702e1cd77755a79bed400d62))
* **db:** missing program mapping for Midea Washmachine MF2000D80WB ([#421](https://github.com/midea-lan/midea-local/issues/421)) ([b459bb3](https://github.com/midea-lan/midea-local/commit/b459bb3b7bd486f72bdcc41b5a8365b96dbbf106))
* **main:** fix default apt/pip mirror; removed deprecated pylint option ([#415](https://github.com/midea-lan/midea-local/issues/415)) ([37fdfcf](https://github.com/midea-lan/midea-local/commit/37fdfcf5bdc3f63a5acd8dcf7efe231124b97257))

## [6.5.0](https://github.com/midea-lan/midea-local/compare/v6.4.0...v6.5.0) (2025-09-26)


### Features

* **a1:** allow customization of default modes and speeds for dehumidifiers ([#389](https://github.com/midea-lan/midea-local/issues/389)) ([bb558a0](https://github.com/midea-lan/midea-local/commit/bb558a03fb31703f28b0d09772034ac8e74aa744))
* **ac:** ac device fan_mode and airflow value support translate ([#390](https://github.com/midea-lan/midea-local/issues/390)) ([a8294cc](https://github.com/midea-lan/midea-local/commit/a8294cc2ddf9c777dd4e27bc09a4e55ba76e5047))
* **ac:** parse capability query respone b5 message ([#407](https://github.com/midea-lan/midea-local/issues/407)) ([def97c2](https://github.com/midea-lan/midea-local/commit/def97c214ef1851ecd78fd88e3929cf8e06c6876))
* **ca:** add new 0xCA device attrs ([#408](https://github.com/midea-lan/midea-local/issues/408)) ([1a87ee6](https://github.com/midea-lan/midea-local/commit/1a87ee6360c0983bbc35e73ace953075ee6ffd01))
* **dc:** Add idle status for dc ([#406](https://github.com/midea-lan/midea-local/issues/406)) ([5459300](https://github.com/midea-lan/midea-local/commit/5459300ef6927ee07a7b7fd5732541d85e77c9d1))
* **e1:** change work mode ([#262](https://github.com/midea-lan/midea-local/issues/262)) ([b1cc880](https://github.com/midea-lan/midea-local/commit/b1cc880b89134efe79da455bcd605f2c94daca01))


### Bug Fixes

* **ac:** fix ac device screen display on and off every 15 mins ([#404](https://github.com/midea-lan/midea-local/issues/404)) ([a6cbea3](https://github.com/midea-lan/midea-local/commit/a6cbea36ff51f52cf755e0b641580ad26041f2ca))
* **dc:** fix attributes parse error  ([#398](https://github.com/midea-lan/midea-local/issues/398)) ([c6f8a3a](https://github.com/midea-lan/midea-local/commit/c6f8a3ad52d3eb3a1f81ea7c32eecb3dd264a2fd))

## [6.4.0](https://github.com/midea-lan/midea-local/compare/v6.3.0...v6.4.0) (2025-08-06)


### Features

* **ac:** ac device support airflow direction control ([#385](https://github.com/midea-lan/midea-local/issues/385)) ([4bd148d](https://github.com/midea-lan/midea-local/commit/4bd148d0bbcb40a316dfe1c3b0eef03d9b7b47ac))


### Bug Fixes

* **ac:** ac device screen_display status error ([#388](https://github.com/midea-lan/midea-local/issues/388)) ([e13962e](https://github.com/midea-lan/midea-local/commit/e13962e8bb429d65aedaed5d15dfa9bc85c77e35))
* **db:** rollback 0xdb progress attr and value ([#386](https://github.com/midea-lan/midea-local/issues/386)) ([ad46461](https://github.com/midea-lan/midea-local/commit/ad4646171144e62ac776a3e64edcc2e0c1e4db5c))

## [6.3.0](https://github.com/midea-lan/midea-local/compare/v6.2.0...v6.3.0) (2025-05-19)


### Features

* **b0:** add b0 device feature ([#365](https://github.com/midea-lan/midea-local/issues/365)) ([1acfde7](https://github.com/midea-lan/midea-local/commit/1acfde75e84218130382cfa351cb5874b26d6160))


### Bug Fixes

* **c3:** temperature should be float ([#369](https://github.com/midea-lan/midea-local/issues/369)) ([f2d8695](https://github.com/midea-lan/midea-local/commit/f2d8695b4b6234d8a2615ea253d6150b03b31028))
* **cd:** parse CD device message error ([#370](https://github.com/midea-lan/midea-local/issues/370)) ([db07d08](https://github.com/midea-lan/midea-local/commit/db07d083621730cb4d3de9cb7303693f7f31c665))
* **cd:** temperature should be float ([#367](https://github.com/midea-lan/midea-local/issues/367)) ([54f16f6](https://github.com/midea-lan/midea-local/commit/54f16f69ca9b558170a03d842ef444143be469ea))
* **e2:** fix e2 device full tank/temperature error ([#371](https://github.com/midea-lan/midea-local/issues/371)) ([182d508](https://github.com/midea-lan/midea-local/commit/182d508862ee9afc29f5d5bc9449ede57986620d))
* **e2:** temperature should be float ([#364](https://github.com/midea-lan/midea-local/issues/364)) ([fec9adf](https://github.com/midea-lan/midea-local/commit/fec9adfbc8be6a3832f367eb8672b48a841c4bd8))
* **e3:** temperature should be float ([#366](https://github.com/midea-lan/midea-local/issues/366)) ([5d27a44](https://github.com/midea-lan/midea-local/commit/5d27a44feb81cff83c7a7a2371cf2221ca85c92f))
* **e6:** temperature should be float ([#368](https://github.com/midea-lan/midea-local/issues/368)) ([bebc217](https://github.com/midea-lan/midea-local/commit/bebc217debecb59cc362ad64663d07896f89cec1))
* **ed:** fix ed device query result is 0 ([#379](https://github.com/midea-lan/midea-local/issues/379)) ([c83b7af](https://github.com/midea-lan/midea-local/commit/c83b7afa35c451842f4c76b1333a3022573b784e))

## [6.2.0](https://github.com/midea-lan/midea-local/compare/v6.1.0...v6.2.0) (2025-03-25)


### Features

* **ad:** add ad device support ([#362](https://github.com/midea-lan/midea-local/issues/362)) ([77e1baa](https://github.com/midea-lan/midea-local/commit/77e1baaf865a6002d6cbea1a6a02c9d345eba866))
* **b3:** support new X00 body for B3 device ([#350](https://github.com/midea-lan/midea-local/issues/350)) ([702aaf0](https://github.com/midea-lan/midea-local/commit/702aaf0dc36d4c3b07bc2607a42a24efee2f13b3))
* **cf:** add defrost and freeze for CF device ([#351](https://github.com/midea-lan/midea-local/issues/351)) ([0762e79](https://github.com/midea-lan/midea-local/commit/0762e7948068e0d5dab236c84f444fbc6ef5f1d0))
* **e6:** add cold water and climate compensation features ([#353](https://github.com/midea-lan/midea-local/issues/353)) ([88b78d0](https://github.com/midea-lan/midea-local/commit/88b78d04d9984bd20dd50c8a3bcced18168f30be))


### Bug Fixes

* **cd:** fix cd device mode key and value error ([#357](https://github.com/midea-lan/midea-local/issues/357)) ([beaf7e0](https://github.com/midea-lan/midea-local/commit/beaf7e0f3492c1348bf21cfffa86f54095824e9b))
* **cloud:** switch default cloud from SmartHome to Nethome Plus ([#360](https://github.com/midea-lan/midea-local/issues/360)) ([ae34281](https://github.com/midea-lan/midea-local/commit/ae342818231b2f6eda92ee35ceb604766575387b))
* **e2:** input target_temperature should be float ([#358](https://github.com/midea-lan/midea-local/issues/358)) ([316afce](https://github.com/midea-lan/midea-local/commit/316afce6a81c202112c6a530057e2e86b9b59904))
* **e3:** input target_temperature should be float ([#359](https://github.com/midea-lan/midea-local/issues/359)) ([377ded9](https://github.com/midea-lan/midea-local/commit/377ded9e90e7debbc0f0cc669b6820c6073df8b6))
* **e6:** input temperature should be float ([#363](https://github.com/midea-lan/midea-local/issues/363)) ([3763412](https://github.com/midea-lan/midea-local/commit/3763412f2fe30d7d5d7d531a8b2965bf9b7a4c62))

## [6.1.0](https://github.com/midea-lan/midea-local/compare/v6.0.3...v6.1.0) (2025-01-15)


### Features

* **c3:** add disinfect and fix tbh set error ([#340](https://github.com/midea-lan/midea-local/issues/340)) ([5f5224b](https://github.com/midea-lan/midea-local/commit/5f5224bbe30f2c02de0ee0ea8d67f5132a4993ab))
* **cd:** add water_level and temperature option with customize lua_protocol ([#345](https://github.com/midea-lan/midea-local/issues/345)) ([db2fdf0](https://github.com/midea-lan/midea-local/commit/db2fdf0bb4aa9d6a9e4ed47c876fd57f57f30c9f))
* **cloud:** add plugin download for meiju and smarthome ([#336](https://github.com/midea-lan/midea-local/issues/336)) ([30de473](https://github.com/midea-lan/midea-local/commit/30de473cd351ff4f7a918452061caf2b5806d876))
* **db:** add new attributes for db device ([#329](https://github.com/midea-lan/midea-local/issues/329)) ([da38007](https://github.com/midea-lan/midea-local/commit/da3800744ed202ca3f4f9ca45f6f784f5e847830))
* **dc:** add new attributes for exist dc device ([#330](https://github.com/midea-lan/midea-local/issues/330)) ([10c15b6](https://github.com/midea-lan/midea-local/commit/10c15b63479f729d421c99341adf3f4f913bdf02))
* **e1:** add new attributes for e1 device ([#337](https://github.com/midea-lan/midea-local/issues/337)) ([9afa160](https://github.com/midea-lan/midea-local/commit/9afa160eccca4641f1a220bdfad2cd611a1cb57b))
* **ed:** add all query msg for 0xED device ([#328](https://github.com/midea-lan/midea-local/issues/328)) ([30ba082](https://github.com/midea-lan/midea-local/commit/30ba082cea0a19a97fd80df3b355236f44d8bcfe))


### Bug Fixes

* fix:  ([db2fdf0](https://github.com/midea-lan/midea-local/commit/db2fdf0bb4aa9d6a9e4ed47c876fd57f57f30c9f))
* **device:** no supported protocol caused high cpu usage ([#346](https://github.com/midea-lan/midea-local/issues/346)) ([013aee4](https://github.com/midea-lan/midea-local/commit/013aee4465480ac2d8cf0f0d047785b6fb6ffeec))


### Documentation

* add collected lua scripts ([#331](https://github.com/midea-lan/midea-local/issues/331)) ([e1a3855](https://github.com/midea-lan/midea-local/commit/e1a385559aec6b1526b10a595ea9a7568a69163c))

## [6.0.3](https://github.com/rokam/midea-local/compare/v6.0.2...v6.0.3) (2024-10-15)


### Bug Fixes

* cleanup and complete body and subbody types lists ([#325](https://github.com/rokam/midea-local/issues/325)) ([914dcb8](https://github.com/rokam/midea-local/commit/914dcb8098efe50cc1583ad81fd22b49e9e2536b))

## [6.0.2](https://github.com/rokam/midea-local/compare/v6.0.1...v6.0.2) (2024-10-08)


### Bug Fixes

* add more BodyType ([#321](https://github.com/rokam/midea-local/issues/321)) ([a1b4ac8](https://github.com/rokam/midea-local/commit/a1b4ac807e3b475f0a32f44c0f1d7af980d7a486))

## [6.0.1](https://github.com/rokam/midea-local/compare/v6.0.0...v6.0.1) (2024-10-06)


### Bug Fixes

* add missing body_type "163" ([#317](https://github.com/rokam/midea-local/issues/317)) ([45f7bd2](https://github.com/rokam/midea-local/commit/45f7bd2432a04fb69c9fdb9b6204de7eac87aa2e))
* message protocol version default ([#316](https://github.com/rokam/midea-local/issues/316)) ([2f4e5d1](https://github.com/rokam/midea-local/commit/2f4e5d1d1335696cc3a179a67cf287eef54b6864))
* protocol check in B6 devices ([#320](https://github.com/rokam/midea-local/issues/320)) ([55659c1](https://github.com/rokam/midea-local/commit/55659c19a642fadfd37aee32fbeae76e48aed3dd))

## [6.0.0](https://github.com/rokam/midea-local/compare/v5.0.0...v6.0.0) (2024-10-03)


### ⚠ BREAKING CHANGES

* **cloud:** rename MSmartHome ([#306](https://github.com/rokam/midea-local/issues/306))

### Miscellaneous Chores

* **cloud:** rename MSmartHome ([#306](https://github.com/rokam/midea-local/issues/306)) ([20c796e](https://github.com/rokam/midea-local/commit/20c796eb9f9728ff4042f3caf2e0ff11012e12f5)), closes [#286](https://github.com/rokam/midea-local/issues/286)

## [5.0.0](https://github.com/rokam/midea-local/compare/v4.0.0...v5.0.0) (2024-10-02)


### ⚠ BREAKING CHANGES

* **device:** rollback and socket refresh_status ([#307](https://github.com/rokam/midea-local/issues/307))

### Bug Fixes

* **device:** rollback and socket refresh_status ([#307](https://github.com/rokam/midea-local/issues/307)) ([f65b6ac](https://github.com/rokam/midea-local/commit/f65b6ac8fcc8ff2ae7085068498b96066213b658))

## [4.0.0](https://github.com/rokam/midea-local/compare/v3.0.1...v4.0.0) (2024-09-29)


### ⚠ BREAKING CHANGES

* **device:** rollback and improve send/recv socket exception ([#304](https://github.com/rokam/midea-local/issues/304))

### Bug Fixes

* **device:** rollback and improve send/recv socket exception ([#304](https://github.com/rokam/midea-local/issues/304)) ([7083464](https://github.com/rokam/midea-local/commit/7083464bba91e2f341d09de3b90b6bc77ccac9cb))

## [3.0.1](https://github.com/rokam/midea-local/compare/v3.0.0...v3.0.1) (2024-09-21)


### Bug Fixes

* **device:** prevent while true loop high cpu usage bug ([#298](https://github.com/rokam/midea-local/issues/298)) ([3bdec5c](https://github.com/rokam/midea-local/commit/3bdec5cbbad960d4fbc5b9a5520fa7c9219fe405))

## [3.0.0](https://github.com/rokam/midea-local/compare/v2.7.1...v3.0.0) (2024-09-20)


### ⚠ BREAKING CHANGES

* **device:** socket exception and process rebuild ([#296](https://github.com/rokam/midea-local/issues/296))

### Bug Fixes

* **device:** socket exception and process rebuild ([#296](https://github.com/rokam/midea-local/issues/296)) ([7f2e572](https://github.com/rokam/midea-local/commit/7f2e57294802d6ecae64618d28d1659465077672))

## [2.7.1](https://github.com/rokam/midea-local/compare/v2.7.0...v2.7.1) (2024-09-12)


### Bug Fixes

* ed device power/lock return message set and body_type 0x15 parse ([#284](https://github.com/rokam/midea-local/issues/284)) ([d9d4fac](https://github.com/rokam/midea-local/commit/d9d4faca3bf7a3096f1e12a53dd5953b79f2a422))

## [2.7.0](https://github.com/rokam/midea-local/compare/v2.6.3...v2.7.0) (2024-08-21)


### Features

* **cli:** use of preset account if cloud info missing ([#278](https://github.com/rokam/midea-local/issues/278)) ([84293bf](https://github.com/rokam/midea-local/commit/84293bfd86b9bb55f59b6897ff5d356df51f7fdb))


### Bug Fixes

* **cloud:** meiju cloud download_lua appliance_type error ([#281](https://github.com/rokam/midea-local/issues/281)) ([54f1bf4](https://github.com/rokam/midea-local/commit/54f1bf4a812c44590d9e01e9cd91c4c0f1768948))

## [2.6.3](https://github.com/rokam/midea-local/compare/v2.6.2...v2.6.3) (2024-08-13)


### Bug Fixes

* body_type default value is zero and not None ([#271](https://github.com/rokam/midea-local/issues/271)) ([bf6b4f0](https://github.com/rokam/midea-local/commit/bf6b4f0d0548bf495339cf793acd30673634f6d1))
* **c3:** silent level as string ([#270](https://github.com/rokam/midea-local/issues/270)) ([c851e33](https://github.com/rokam/midea-local/commit/c851e33dc9e8f7bb5a2f7d49f2e7c557d3a7151f))

## [2.6.2](https://github.com/rokam/midea-local/compare/v2.6.1...v2.6.2) (2024-08-10)


### Bug Fixes

* **cli:** discover must return a list ([#266](https://github.com/rokam/midea-local/issues/266)) ([345794b](https://github.com/rokam/midea-local/commit/345794b1241c149c172c117412ed48707daff6b9))

## [2.6.1](https://github.com/rokam/midea-local/compare/v2.6.0...v2.6.1) (2024-08-09)


### Bug Fixes

* **c3:** silent typo ([#265](https://github.com/rokam/midea-local/issues/265)) ([97defcd](https://github.com/rokam/midea-local/commit/97defcdc100424992c0f2bc7d4797cbbb6825076))
* **cli:** authenticate on discover v3 device ([#263](https://github.com/rokam/midea-local/issues/263)) ([05b0b11](https://github.com/rokam/midea-local/commit/05b0b11d98a3435373742c2cf50142f618700ed1))

## [2.6.0](https://github.com/rokam/midea-local/compare/v2.5.0...v2.6.0) (2024-08-02)


### Features

* parse all the response items from MeijuCloud for get_device_inf ([#231](https://github.com/rokam/midea-local/issues/231)) ([1976eb6](https://github.com/rokam/midea-local/commit/1976eb63578698d2b9a745a92c9c61a887219e0d))


### Bug Fixes

* **cli:** authenticate to get keys ([#256](https://github.com/rokam/midea-local/issues/256)) ([a017e7a](https://github.com/rokam/midea-local/commit/a017e7af46130266226f6c9a100b05703dd6cb5c))
* tank is always seen as full ([#255](https://github.com/rokam/midea-local/issues/255)) ([3524405](https://github.com/rokam/midea-local/commit/3524405fd36131deb83c9ded236eb686860f58c2))

## [2.5.0](https://github.com/rokam/midea-local/compare/v2.4.0...v2.5.0) (2024-07-30)


### Features

* **40:** add `precision_halves` customization ([#248](https://github.com/rokam/midea-local/issues/248)) ([8f5ec79](https://github.com/rokam/midea-local/commit/8f5ec79fe859ad88519360353cd3b6e159200625))
* **b8:** first implementation ([#225](https://github.com/rokam/midea-local/issues/225)) ([259e4f2](https://github.com/rokam/midea-local/commit/259e4f2f715b38a280789530941acc53d98beca4))


### Bug Fixes

* `break` the loop when connected ([#244](https://github.com/rokam/midea-local/issues/244)) ([536f975](https://github.com/rokam/midea-local/commit/536f975b93a3d68466a1bfa5a7c152570121531e))
* **ac:** correct attributes based on msg type ([#251](https://github.com/rokam/midea-local/issues/251)) ([fada9bc](https://github.com/rokam/midea-local/commit/fada9bc5fcc4158a6315566b8e9372c8805e21b4))
* **cloud:** fix email obfuscation ([#245](https://github.com/rokam/midea-local/issues/245)) ([ad9f278](https://github.com/rokam/midea-local/commit/ad9f278c7284e7e80285d66adc8320bb944f1162))

## [2.4.0](https://github.com/rokam/midea-local/compare/v2.3.0...v2.4.0) (2024-07-24)


### Features

* **cli:** set attribute from device ([#241](https://github.com/rokam/midea-local/issues/241)) ([6f0a109](https://github.com/rokam/midea-local/commit/6f0a10942c0b5defd3622c14bcd2795b34ec01a8))
* segregate connect/auth/refresh/enable device duties ([#233](https://github.com/rokam/midea-local/issues/233)) ([681bd79](https://github.com/rokam/midea-local/commit/681bd79f078deafe82cc4708f47c53c808dca064))

## [2.3.0](https://github.com/rokam/midea-local/compare/v2.2.0...v2.3.0) (2024-07-23)


### Features

* **message:** body parsers ([#235](https://github.com/rokam/midea-local/issues/235)) ([c636eee](https://github.com/rokam/midea-local/commit/c636eeef5128504c079704d023e2215896e3c770))

## [2.2.0](https://github.com/rokam/midea-local/compare/v2.1.1...v2.2.0) (2024-07-20)


### Features

* redact data from cloud ([#232](https://github.com/rokam/midea-local/issues/232)) ([c61991e](https://github.com/rokam/midea-local/commit/c61991eb93ca817d6245328fe1f5828a33dc5738))

## [2.1.1](https://github.com/rokam/midea-local/compare/v2.1.0...v2.1.1) (2024-07-16)


### Bug Fixes

* **cloud:** get default keys as static ([#229](https://github.com/rokam/midea-local/issues/229)) ([815643a](https://github.com/rokam/midea-local/commit/815643a1a59a14863090b0cdd65170605a8b91da))

## [2.1.0](https://github.com/rokam/midea-local/compare/v2.0.0...v2.1.0) (2024-07-16)


### Features

* **c3:** add option to set super_silent ([#210](https://github.com/rokam/midea-local/issues/210)) ([dcef500](https://github.com/rokam/midea-local/commit/dcef500f073ce150283730132fd4a3155850e332))
* **c3:** query and set silence level ([#227](https://github.com/rokam/midea-local/issues/227)) ([556f7c2](https://github.com/rokam/midea-local/commit/556f7c234d4581472b0ce2f3830289b2ba529c90))

## [2.0.0](https://github.com/rokam/midea-local/compare/v1.3.2...v2.0.0) (2024-07-12)


### ⚠ BREAKING CHANGES

* rework auth flow - part 1 ([#219](https://github.com/rokam/midea-local/issues/219)) ([d8ac4fb](https://github.com/rokam/midea-local/commit/d8ac4fb5de25dbf04548b411f5a930878b32a2df))

### Features

* **cli:** download protocol ([#214](https://github.com/rokam/midea-local/issues/214)) ([7a99374](https://github.com/rokam/midea-local/commit/7a993745c0c7fcf1e9eff86a2287e3cbff3f3d8d))
* rework auth flow - part 1 ([#219](https://github.com/rokam/midea-local/issues/219)) ([d8ac4fb](https://github.com/rokam/midea-local/commit/d8ac4fb5de25dbf04548b411f5a930878b32a2df))
* rework auth flow - part 2 ([#221](https://github.com/rokam/midea-local/issues/221)) ([f74ff8e](https://github.com/rokam/midea-local/commit/f74ff8e1af924d84621958d0c6d8659cef1b98e6))

## [1.3.2](https://github.com/rokam/midea-local/compare/v1.3.1...v1.3.2) (2024-07-11)


### Bug Fixes

* **capabilities:** make capabilities optional ([#217](https://github.com/rokam/midea-local/issues/217)) ([c269e71](https://github.com/rokam/midea-local/commit/c269e717c2b2b5e7f390f0e2ba781513584442b2))

## [1.3.1](https://github.com/rokam/midea-local/compare/v1.3.0...v1.3.1) (2024-07-10)


### Bug Fixes

* wrong dependencies with package ([#215](https://github.com/rokam/midea-local/issues/215)) ([d63fc6b](https://github.com/rokam/midea-local/commit/d63fc6b49394f9bfc9c9cb32b34c36b5e97f02a6))

## [1.3.0](https://github.com/rokam/midea-local/compare/v1.2.0...v1.3.0) (2024-07-10)


### Features

* **c3:** temperature step as customize ([#209](https://github.com/rokam/midea-local/issues/209)) ([4da6e3e](https://github.com/rokam/midea-local/commit/4da6e3eb18eae9b24b4300274e307db0af8633de))
* **cli:** midealocal CLI tool ([#204](https://github.com/rokam/midea-local/issues/204)) ([236e33a](https://github.com/rokam/midea-local/commit/236e33a95fde65aba499832bb6901f32ac21628d))


### Bug Fixes

* **device:** capabilities ([#212](https://github.com/rokam/midea-local/issues/212)) ([f7cff37](https://github.com/rokam/midea-local/commit/f7cff3767522a6f1008a5f7b4ef8677ecd9296bc))

## [1.2.0](https://github.com/rokam/midea-local/compare/v1.1.4...v1.2.0) (2024-07-08)


### Features

* **ac:** mode capabilities ([#196](https://github.com/rokam/midea-local/issues/196)) ([43d9918](https://github.com/rokam/midea-local/commit/43d9918be79f8dbb4f8b126d121619d04efe47cf))


### Bug Fixes

* **da:** avoid indexes out of bounds ([#199](https://github.com/rokam/midea-local/issues/199)) ([246f9c7](https://github.com/rokam/midea-local/commit/246f9c752f49a5425e06ea1b3772347bc4eb3880))
* rollback get_keys with 3 keys ([#200](https://github.com/rokam/midea-local/issues/200)) ([54153a8](https://github.com/rokam/midea-local/commit/54153a8fd24c5f5ae3ef2b02e7ef863d18bc998a))
