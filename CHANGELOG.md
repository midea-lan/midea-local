# Changelog

## [11.0.1](https://github.com/midea-lan/midea-local/compare/v11.0.0...v11.0.1) (2026-09-05)


### Bug Fixes

* **cloud:** expose a translation_key on MideaCloudError ([#757](https://github.com/midea-lan/midea-local/issues/757)) ([133dc54](https://github.com/midea-lan/midea-local/commit/133dc54b9d2880dbeebc6d4bf79c21e735240ffe))

## [11.0.0](https://github.com/midea-lan/midea-local/compare/v10.1.0...v11.0.0) (2026-09-05)


### ⚠ BREAKING CHANGES

* **cloud:** raise typed errors for known cloud API failure codes ([#747](https://github.com/midea-lan/midea-local/issues/747))

### Features

* **a1:** expose device capabilities ([#754](https://github.com/midea-lan/midea-local/issues/754)) ([ea33031](https://github.com/midea-lan/midea-local/commit/ea3303168555dfec57e4721454794ede083216fc))
* **ac:** add group 3 outdoor fan speed ([#736](https://github.com/midea-lan/midea-local/issues/736)) ([d8027fc](https://github.com/midea-lan/midea-local/commit/d8027fc3c8c37d64cc0cd2ae1d227a56874f1d12))
* **ac:** capabilities remove unsupported attrs ([#746](https://github.com/midea-lan/midea-local/issues/746)) ([27aa14b](https://github.com/midea-lan/midea-local/commit/27aa14bca5fb10e53a8bd934b34e7ccd6ab4033c))
* add OS Comfort (Olimpia Splendid) cloud ([#752](https://github.com/midea-lan/midea-local/issues/752)) ([7a5360c](https://github.com/midea-lan/midea-local/commit/7a5360c784f646d9330881ea448ba7d90c45add7))
* add public metod mode_options() ([#745](https://github.com/midea-lan/midea-local/issues/745)) ([e1f6b04](https://github.com/midea-lan/midea-local/commit/e1f6b040f0c8de900cc386f136a1948171125126))
* **cd:** support extended water heater protocol ([#735](https://github.com/midea-lan/midea-local/issues/735)) ([8916a31](https://github.com/midea-lan/midea-local/commit/8916a3105356d491ea93ba97034f2831fcb1b0b8))
* **cloud:** add support for Japanese Toshiba IOLife devices ([#301](https://github.com/midea-lan/midea-local/issues/301)) ([f357970](https://github.com/midea-lan/midea-local/commit/f3579707342eec1c0103d2ac254f436ba49a3c2d))
* **cloud:** classify 3101/3106/3301 as login errors ([#751](https://github.com/midea-lan/midea-local/issues/751)) ([2a8a4f0](https://github.com/midea-lan/midea-local/commit/2a8a4f0a89577e3a74c7476eae0e1228771ebf6d))
* introduce MideaClimateDevice base class ([#728](https://github.com/midea-lan/midea-local/issues/728)) ([303ac20](https://github.com/midea-lan/midea-local/commit/303ac2034c7d4597326137c30d39a693f0005130))


### Bug Fixes

* **ac:** default values for make message set when missing DeviceAttributes ([#755](https://github.com/midea-lan/midea-local/issues/755)) ([0c979b0](https://github.com/midea-lan/midea-local/commit/0c979b0a88b359a91db4d23004ff73cf37ee7303))
* **c3:** align to climate platform ([#730](https://github.com/midea-lan/midea-local/issues/730)) ([c6fed4d](https://github.com/midea-lan/midea-local/commit/c6fed4d99241d506e564a95d368eaeb095c40792))
* **cc:** align to climate platform ([#729](https://github.com/midea-lan/midea-local/issues/729)) ([12b0b89](https://github.com/midea-lan/midea-local/commit/12b0b893e8e9c781b180072dee61a2c24c9628ee))
* **cf:** align to climate platform ([#731](https://github.com/midea-lan/midea-local/issues/731)) ([de01976](https://github.com/midea-lan/midea-local/commit/de01976c2f33db78990891fae70208fe3095eec0))
* **cloud:** retry transient 9999 system error responses ([#750](https://github.com/midea-lan/midea-local/issues/750)) ([8857000](https://github.com/midea-lan/midea-local/commit/8857000faa40959caec6e08057c2c7d90cdc69d1))
* **cloud:** use the v2 getToken endpoint for the Meiju cloud ([#717](https://github.com/midea-lan/midea-local/issues/717)) ([d819de1](https://github.com/midea-lan/midea-local/commit/d819de146eb875bf9a46fb0ab932bc9be375a3ea))
* **fb:** align to climate platform ([#732](https://github.com/midea-lan/midea-local/issues/732)) ([197657d](https://github.com/midea-lan/midea-local/commit/197657d1b8e568a30f167994b6dbced621da798a))


### Code Refactoring

* **cloud:** raise typed errors for known cloud API failure codes ([#747](https://github.com/midea-lan/midea-local/issues/747)) ([7854642](https://github.com/midea-lan/midea-local/commit/78546422e0eea45183bc573bc19b38a229698c5c))

## [10.1.0](https://github.com/midea-lan/midea-local/compare/v10.0.1...v10.1.0) (2026-08-28)


### Features

* expose min and max temperature for E2 and E3 ([#721](https://github.com/midea-lan/midea-local/issues/721)) ([8f19801](https://github.com/midea-lan/midea-local/commit/8f19801af65729088638a59033d4ad3ad207e2ff))
* **message:** add byte_mask to BodyParser ([#725](https://github.com/midea-lan/midea-local/issues/725)) ([7a75ab6](https://github.com/midea-lan/midea-local/commit/7a75ab6938c1038eb392351307996903cafd9e55))


### Bug Fixes

* **ca:** guard CAGeneralMessageBody against short payloads ([#700](https://github.com/midea-lan/midea-local/issues/700)) ([ab52b77](https://github.com/midea-lan/midea-local/commit/ab52b77d2f64756168999a382dbe680ae6d66733))
* **cloud:** support legacy lua download for MideaAirCloud ([#599](https://github.com/midea-lan/midea-local/issues/599)) ([57f61d0](https://github.com/midea-lan/midea-local/commit/57f61d02a9da6216c378423a09c8f0db4851475f))
* **device:** follow up of [#690](https://github.com/midea-lan/midea-local/issues/690) ([#719](https://github.com/midea-lan/midea-local/issues/719)) ([ad3f10c](https://github.com/midea-lan/midea-local/commit/ad3f10cddefb93351faaf9453288cf7a1a9cbe05))
* **e6:** heating_modes must be named preset_modes for compatibility ([#722](https://github.com/midea-lan/midea-local/issues/722)) ([5632819](https://github.com/midea-lan/midea-local/commit/563281941bb3475d68ecd6561b47e584a9297ac5))
* **e8:** guard E8MessageBody against short payloads ([#699](https://github.com/midea-lan/midea-local/issues/699)) ([002e0a4](https://github.com/midea-lan/midea-local/commit/002e0a45e90b5e3e7d73e5d32be571647de8b758))

## [10.0.1](https://github.com/midea-lan/midea-local/compare/v10.0.0...v10.0.1) (2026-08-23)


### Bug Fixes

* **e1:** align modes,status,progress style ([#714](https://github.com/midea-lan/midea-local/issues/714)) ([4188142](https://github.com/midea-lan/midea-local/commit/418814280c94172083edca8bb742ca884ba82ea6))
* **e3:** align old_subtypes style ([#713](https://github.com/midea-lan/midea-local/issues/713)) ([f30fb15](https://github.com/midea-lan/midea-local/commit/f30fb1566947d44f00a0212e38129bf957bcf005))
* **fa:** align fan modes ([#712](https://github.com/midea-lan/midea-local/issues/712)) ([264ab1c](https://github.com/midea-lan/midea-local/commit/264ab1ce9a2a1a80d7d93a0c8763c3bf7ad7a03d))
* **x34:** align modes,status,progress style ([#715](https://github.com/midea-lan/midea-local/issues/715)) ([bd1b3d0](https://github.com/midea-lan/midea-local/commit/bd1b3d08b4614f44b8a4669944f1330c73f78656))

## [10.0.0](https://github.com/midea-lan/midea-local/compare/v9.0.0...v10.0.0) (2026-08-22)


### ⚠ BREAKING CHANGES

* **x13:** improve effects naming ([#689](https://github.com/midea-lan/midea-local/issues/689))

### Bug Fixes

* **ac:** guard XA1MessageBody parsing against short notify bodies ([#691](https://github.com/midea-lan/midea-local/issues/691)) ([3297742](https://github.com/midea-lan/midea-local/commit/3297742ed593e0e38d269445a449068cb5fb3bea)), closes [#688](https://github.com/midea-lan/midea-local/issues/688)
* **ac:** keep unit on when a mode change is followed by a temperature write ([#601](https://github.com/midea-lan/midea-local/issues/601)) ([065ad21](https://github.com/midea-lan/midea-local/commit/065ad214b2a71c2802a94bd67ed9f118ace72fea))
* **ac:** missing B5-derived modes ([#681](https://github.com/midea-lan/midea-local/issues/681)) ([9e4b513](https://github.com/midea-lan/midea-local/commit/9e4b513b8c6eb96444a6632d319e6cd4226086a5))
* **b8:** handle unknown error sub-codes in MessageB8GenericBody ([#696](https://github.com/midea-lan/midea-local/issues/696)) ([dc12e8f](https://github.com/midea-lan/midea-local/commit/dc12e8f9114140534bb5a333173ba6902ddb06e2))
* **bf:** align water state attribute name ([#708](https://github.com/midea-lan/midea-local/issues/708)) ([bd6baa3](https://github.com/midea-lan/midea-local/commit/bd6baa3a692595e650df215b25f8ccafa3885f92))
* **c3:** use correct zone when reading temperature type ([#707](https://github.com/midea-lan/midea-local/issues/707)) ([c17fb6e](https://github.com/midea-lan/midea-local/commit/c17fb6e488430fbd4f30170517ba7ff99ba44d9f))
* **cc:** avoid crash on stale fan speed ([#682](https://github.com/midea-lan/midea-local/issues/682)) ([6ca3f1c](https://github.com/midea-lan/midea-local/commit/6ca3f1c90d7b8dd04a2f7b81ab2a40e191ab10ea))
* **cd:** support Kosner 2530001N and sync power with mode selection ([#684](https://github.com/midea-lan/midea-local/issues/684)) ([d9f3a9b](https://github.com/midea-lan/midea-local/commit/d9f3a9bae70b299e593aec1ffda9551669f9c0a9))
* **ce:** improve modes naming ([#680](https://github.com/midea-lan/midea-local/issues/680)) ([08b5c11](https://github.com/midea-lan/midea-local/commit/08b5c116754764c2dee6feb668a86b6e9c6f8430))
* **device:** prevent appliance query from masking failed status queries ([#690](https://github.com/midea-lan/midea-local/issues/690)) ([c64d977](https://github.com/midea-lan/midea-local/commit/c64d9778aba9e9c96c2ac64b8960746b23926317))
* **device:** retry query once before marking protocol unsupported ([#694](https://github.com/midea-lan/midea-local/issues/694)) ([922e27c](https://github.com/midea-lan/midea-local/commit/922e27c579d6871080bf31581aaac20d3264af40))
* **fa:** add opt-in mode override for fan devices ([#686](https://github.com/midea-lan/midea-local/issues/686)) ([2e5c07e](https://github.com/midea-lan/midea-local/commit/2e5c07e27d9bacec42c68875df70129642082c10))
* **fa:** validate mode_set_overrides values are bytes ([#693](https://github.com/midea-lan/midea-local/issues/693)) ([c4c0693](https://github.com/midea-lan/midea-local/commit/c4c0693502849a955f3fab9d51dbc2ea990cc228))
* **fc:** correct FCNotifyMessageBody standby bitmask check ([#698](https://github.com/midea-lan/midea-local/issues/698)) ([8fe1c6d](https://github.com/midea-lan/midea-local/commit/8fe1c6d92829f5f6da4cdfc7d0fc533821bf605b))
* skip updates on shutdown ([#683](https://github.com/midea-lan/midea-local/issues/683)) ([14364d2](https://github.com/midea-lan/midea-local/commit/14364d2dbb3500378d5c534ae90dfe444cf63314))
* **x13:** improve effects naming ([#689](https://github.com/midea-lan/midea-local/issues/689)) ([ed3fc6a](https://github.com/midea-lan/midea-local/commit/ed3fc6ad628615a27fb303843935601e5a44c546))
* **x26:** handle set_attribute before initial status update ([#701](https://github.com/midea-lan/midea-local/issues/701)) ([5654d02](https://github.com/midea-lan/midea-local/commit/5654d02fa5743140ef2bc0bd1f86f1cb8dcf3099))

## [9.0.0](https://github.com/midea-lan/midea-local/compare/v8.0.1...v9.0.0) (2026-08-15)


### ⚠ BREAKING CHANGES

* **cd:** modes snakecase ([#652](https://github.com/midea-lan/midea-local/issues/652))
* **b0:** standard to snake_case attributes ([#642](https://github.com/midea-lan/midea-local/issues/642))
* **ce:** snakecase modes ([#653](https://github.com/midea-lan/midea-local/issues/653))
* **e1:** snakecase standard ([#657](https://github.com/midea-lan/midea-local/issues/657))
* **e8:** snakecase status ([#659](https://github.com/midea-lan/midea-local/issues/659))
* **da:** multiple snakecase standard ([#654](https://github.com/midea-lan/midea-local/issues/654))
* **e6:** snakecase heatingmode ([#658](https://github.com/midea-lan/midea-local/issues/658))
* **db:** multiple snakecase standard ([#655](https://github.com/midea-lan/midea-local/issues/655))
* **x13:** snakecase effects ([#668](https://github.com/midea-lan/midea-local/issues/668))
* **ea:** snakecase progress ([#660](https://github.com/midea-lan/midea-local/issues/660))
* **x40:** snakecase directions ([#671](https://github.com/midea-lan/midea-local/issues/671))
* **x34:** snakecase modes, status and progress ([#670](https://github.com/midea-lan/midea-local/issues/670))
* **fd:** snakecase modes, speeds, screen_display and detect_modes ([#666](https://github.com/midea-lan/midea-local/issues/666))
* **fc:** snakecase modes, speeds, screen_display and detect_modes ([#665](https://github.com/midea-lan/midea-local/issues/665))
* **fb:** snakecase modes ([#664](https://github.com/midea-lan/midea-local/issues/664))
* **fa:** snakecase mode and oscillation ([#663](https://github.com/midea-lan/midea-local/issues/663))
* **x26:** snakecase modes and directions ([#669](https://github.com/midea-lan/midea-local/issues/669))
* **c3:** snake_case silent level ([#649](https://github.com/midea-lan/midea-local/issues/649))
* **dc:** snakecase progress ([#656](https://github.com/midea-lan/midea-local/issues/656))
* **ec:** progress snakecase ([#662](https://github.com/midea-lan/midea-local/issues/662))
* **b6:** snake_case speeds ([#647](https://github.com/midea-lan/midea-local/issues/647))
* **b4:** status snake_case format ([#646](https://github.com/midea-lan/midea-local/issues/646))
* **cc:** fan_speed snake_case ([#650](https://github.com/midea-lan/midea-local/issues/650))
* **b3:** snake_case status ([#645](https://github.com/midea-lan/midea-local/issues/645))
* **b1:** snake_case status ([#644](https://github.com/midea-lan/midea-local/issues/644))
* **bf:** status snake_case ([#648](https://github.com/midea-lan/midea-local/issues/648))
* **ac:** standard snake_case for wind_angles ([#641](https://github.com/midea-lan/midea-local/issues/641))
* **a1:** standard snakecase for fan_speed and mode ([#640](https://github.com/midea-lan/midea-local/issues/640))

### Bug Fixes

* **a1:** standard snakecase for fan_speed and mode ([#640](https://github.com/midea-lan/midea-local/issues/640)) ([acd737a](https://github.com/midea-lan/midea-local/commit/acd737ab84e60158858d451eb50c8418a3c6e5b7))
* **ac:** standard snake_case for wind_angles ([#641](https://github.com/midea-lan/midea-local/issues/641)) ([988cf2b](https://github.com/midea-lan/midea-local/commit/988cf2b450c4ea382f991ae8920afabadbf7f23c))
* **b0:** standard to snake_case attributes ([#642](https://github.com/midea-lan/midea-local/issues/642)) ([10b8c8a](https://github.com/midea-lan/midea-local/commit/10b8c8a03f445a4e1536e47d30c1f58c762621e9))
* **b1:** snake_case status ([#644](https://github.com/midea-lan/midea-local/issues/644)) ([b1d561c](https://github.com/midea-lan/midea-local/commit/b1d561c38bc333624597bde7ed56ac8117f757b8))
* **b3:** snake_case status ([#645](https://github.com/midea-lan/midea-local/issues/645)) ([57aa0c9](https://github.com/midea-lan/midea-local/commit/57aa0c947994f0e84621ea634e59f8a6ec144a03))
* **b4:** status snake_case format ([#646](https://github.com/midea-lan/midea-local/issues/646)) ([bf782dc](https://github.com/midea-lan/midea-local/commit/bf782dc79d8532e876040e2c1ea04e9e5950a9b5))
* **b6:** snake_case speeds ([#647](https://github.com/midea-lan/midea-local/issues/647)) ([b5e451f](https://github.com/midea-lan/midea-local/commit/b5e451f85d85fd6abf5d9b471e635b6a672e4531))
* **bf:** status snake_case ([#648](https://github.com/midea-lan/midea-local/issues/648)) ([bcdf74e](https://github.com/midea-lan/midea-local/commit/bcdf74ea34ea5e9fab5873c9dd21f402edd4f28d))
* **c3:** eco message index out of bounds ([#661](https://github.com/midea-lan/midea-local/issues/661)) ([a487d63](https://github.com/midea-lan/midea-local/commit/a487d630ca39d4f3f7326c7a42a96545a32448da))
* **c3:** snake_case silent level ([#649](https://github.com/midea-lan/midea-local/issues/649)) ([9b4f9b5](https://github.com/midea-lan/midea-local/commit/9b4f9b5a7df381ce35098e2b11017f76639f9e1b))
* **cc:** fan_speed snake_case ([#650](https://github.com/midea-lan/midea-local/issues/650)) ([373d9b5](https://github.com/midea-lan/midea-local/commit/373d9b57d5723d9f0099c130ff13eb23ae8dfd10))
* **cd:** modes snakecase ([#652](https://github.com/midea-lan/midea-local/issues/652)) ([5ddc6de](https://github.com/midea-lan/midea-local/commit/5ddc6de864c39268e4e5b42f24d10c891999720c))
* **ce:** snakecase modes ([#653](https://github.com/midea-lan/midea-local/issues/653)) ([55168a1](https://github.com/midea-lan/midea-local/commit/55168a1d5854a98202612499d41cf4a0957a2fa7))
* **da:** multiple snakecase standard ([#654](https://github.com/midea-lan/midea-local/issues/654)) ([21fe472](https://github.com/midea-lan/midea-local/commit/21fe472d3031798a6f28d695d90c766841225f5d))
* **db:** multiple snakecase standard ([#655](https://github.com/midea-lan/midea-local/issues/655)) ([1119836](https://github.com/midea-lan/midea-local/commit/1119836cf4f5031a88a00c07c17ea2db40b8b29d))
* **dc:** snakecase progress ([#656](https://github.com/midea-lan/midea-local/issues/656)) ([d96490b](https://github.com/midea-lan/midea-local/commit/d96490beabae9ace1da3ce8fd76739a056c9b496))
* **e1:** snakecase standard ([#657](https://github.com/midea-lan/midea-local/issues/657)) ([3ea015b](https://github.com/midea-lan/midea-local/commit/3ea015bcf5f8f0f5fdde1a333843c5fc04ddb7b6))
* **e6:** snakecase heatingmode ([#658](https://github.com/midea-lan/midea-local/issues/658)) ([6f5070b](https://github.com/midea-lan/midea-local/commit/6f5070b1c18466c9b1981fefaa96c953bb2e8065))
* **e8:** snakecase status ([#659](https://github.com/midea-lan/midea-local/issues/659)) ([2906885](https://github.com/midea-lan/midea-local/commit/2906885d2a71f939b0cc379436ae145ed93a5e1b))
* **ea:** snakecase progress ([#660](https://github.com/midea-lan/midea-local/issues/660)) ([947ee84](https://github.com/midea-lan/midea-local/commit/947ee84303c8d07a436bc99f3ed38df962ff92f3))
* **ec:** progress snakecase ([#662](https://github.com/midea-lan/midea-local/issues/662)) ([2e95f91](https://github.com/midea-lan/midea-local/commit/2e95f91a2e6dc6b442c7abcb149480d982e1218d))
* **fa:** snakecase mode and oscillation ([#663](https://github.com/midea-lan/midea-local/issues/663)) ([633ca30](https://github.com/midea-lan/midea-local/commit/633ca30389b4448554044f7f1365e55b80298129))
* **fb:** snakecase modes ([#664](https://github.com/midea-lan/midea-local/issues/664)) ([356d652](https://github.com/midea-lan/midea-local/commit/356d6525fe984d7ae8ca2e02246977f96c574985))
* **fc:** snakecase modes, speeds, screen_display and detect_modes ([#665](https://github.com/midea-lan/midea-local/issues/665)) ([9254b23](https://github.com/midea-lan/midea-local/commit/9254b23c4642350f0bfd4ea27faeee76f5786eec))
* **fd:** snakecase modes, speeds, screen_display and detect_modes ([#666](https://github.com/midea-lan/midea-local/issues/666)) ([36743ce](https://github.com/midea-lan/midea-local/commit/36743ce0949e5ff300065af9e673dc3048f0f445))
* **x13:** snakecase effects ([#668](https://github.com/midea-lan/midea-local/issues/668)) ([3e82844](https://github.com/midea-lan/midea-local/commit/3e82844a295d28d6acf6e7cfae1d99d19bfbfbdd))
* **x26:** snakecase modes and directions ([#669](https://github.com/midea-lan/midea-local/issues/669)) ([f1e840f](https://github.com/midea-lan/midea-local/commit/f1e840f3d17bf7b40321f7e144dc1b8e441f4152))
* **x34:** snakecase modes, status and progress ([#670](https://github.com/midea-lan/midea-local/issues/670)) ([11273c1](https://github.com/midea-lan/midea-local/commit/11273c1b0ab566f2488da5f753ba6996f76b6580))
* **x40:** snakecase directions ([#671](https://github.com/midea-lan/midea-local/issues/671)) ([a47b587](https://github.com/midea-lan/midea-local/commit/a47b587e0f35d4828bf3a02c9a08fcbaabc041b2))

## [8.0.1](https://github.com/midea-lan/midea-local/compare/midea-local-v8.0.0...midea-local-v8.0.1) (2026-08-13)


### Bug Fixes

* **b0:** correct status labels 0x02/0x03 (Idle/Working, not Working/Pause) on subtype zero ([#634](https://github.com/midea-lan/midea-local/issues/634)) ([7b4b856](https://github.com/midea-lan/midea-local/commit/7b4b856151b55a015f0d3384f3664ec8dbf214e6))
* **ed:** cancel queued tea bar heating after filling ([#638](https://github.com/midea-lan/midea-local/issues/638)) ([5297dce](https://github.com/midea-lan/midea-local/commit/5297dce739ff88c46f22b656f1f0dbd8c7ceed59))
* **x40:** align with other device fan implementations ([#637](https://github.com/midea-lan/midea-local/issues/637)) ([4564297](https://github.com/midea-lan/midea-local/commit/4564297408a21bf29b30b233b23882d58f08bebf))

## [8.0.0](https://github.com/midea-lan/midea-local/compare/midea-local-v7.0.0...midea-local-v8.0.0) (2026-08-12)


### ⚠ BREAKING CHANGES

* **ac:** rename T1/T2/T3 group 1 temperature attributes ([#630](https://github.com/midea-lan/midea-local/issues/630))
* **ac:** rename subtype8 temperature names to new_protocol ([#605](https://github.com/midea-lan/midea-local/issues/605))
* **c3:** normalize silent_level attribute naming ([#620](https://github.com/midea-lan/midea-local/issues/620))
* **b8:** rename B8DeviceAttributes for consistency ([#615](https://github.com/midea-lan/midea-local/issues/615))

### Features

* **ac:** gate rate_select query behind b5_electricity capability ([#632](https://github.com/midea-lan/midea-local/issues/632)) ([30bd23b](https://github.com/midea-lan/midea-local/commit/30bd23bdf427b5fe109d567011d3825f1d046044))
* **b1:** decode X01 fallback query responses ([#633](https://github.com/midea-lan/midea-local/issues/633)) ([3ba0908](https://github.com/midea-lan/midea-local/commit/3ba09086e5d62769da8cf889e7aa5271448c60da))
* **ed:** support subtype 395 tea bar appliances ([#628](https://github.com/midea-lan/midea-local/issues/628)) ([b4c811b](https://github.com/midea-lan/midea-local/commit/b4c811b812de0ee49fe65a5fae83367ce26de741))


### Bug Fixes

* **ac:** report self-clean status correcly ([#619](https://github.com/midea-lan/midea-local/issues/619)) ([1804c5a](https://github.com/midea-lan/midea-local/commit/1804c5ac6ed38f553beaf3a051730e611625712b))
* **b0:** ignore 31 body on subtype zero devices ([#629](https://github.com/midea-lan/midea-local/issues/629)) ([569cc83](https://github.com/midea-lan/midea-local/commit/569cc83d8fcc94861ee3931af34e1d538e146195))
* **b6:** turn_on evaluation ([#613](https://github.com/midea-lan/midea-local/issues/613)) ([14ecf24](https://github.com/midea-lan/midea-local/commit/14ecf246deb779f21a4be72c4e52a2157a49cebd))
* **ca:** transmit translated values ([#611](https://github.com/midea-lan/midea-local/issues/611)) ([4a387ed](https://github.com/midea-lan/midea-local/commit/4a387ed248eb589e62fc26ceea2c9253ae44aa99))
* **cf:** attribute values validation ([#612](https://github.com/midea-lan/midea-local/issues/612)) ([f41758c](https://github.com/midea-lan/midea-local/commit/f41758c9ec11da0cb45c61d411c5804bdcd62fd5))
* **cli:** namespace guard to get_sn attr ([#627](https://github.com/midea-lan/midea-local/issues/627)) ([cb87bf4](https://github.com/midea-lan/midea-local/commit/cb87bf4bc4ecf9550fd0e6857cb95f46dbc771fa))
* **e2:** encode subtype 255 temperature literally ([#621](https://github.com/midea-lan/midea-local/issues/621)) ([f87b89d](https://github.com/midea-lan/midea-local/commit/f87b89dc9fd1fbe8a51f4e1c26a2ba5496f6421b))
* **fa:** turn_on evaluation ([#614](https://github.com/midea-lan/midea-local/issues/614)) ([61c3ee6](https://github.com/midea-lan/midea-local/commit/61c3ee6bffda8eca4c26a540e25514864cac7aaa))
* included typing_extensions to requirements ([#604](https://github.com/midea-lan/midea-local/issues/604)) ([35ec51e](https://github.com/midea-lan/midea-local/commit/35ec51ebe59d86106038d8d006a5ae4f4445e191))


### Code Refactoring

* **ac:** rename subtype8 temperature names to new_protocol ([#605](https://github.com/midea-lan/midea-local/issues/605)) ([4e7edd8](https://github.com/midea-lan/midea-local/commit/4e7edd81c25ff9f2961e896406b78960b5ecf2bd))
* **ac:** rename T1/T2/T3 group 1 temperature attributes ([#630](https://github.com/midea-lan/midea-local/issues/630)) ([ea91809](https://github.com/midea-lan/midea-local/commit/ea918097708cb07597623807af80208c87635d6c))
* **b8:** rename B8DeviceAttributes for consistency ([#615](https://github.com/midea-lan/midea-local/issues/615)) ([69889e1](https://github.com/midea-lan/midea-local/commit/69889e1168d34b4184272634679daea125ca6947))
* **c3:** normalize silent_level attribute naming ([#620](https://github.com/midea-lan/midea-local/issues/620)) ([049f750](https://github.com/midea-lan/midea-local/commit/049f750b584424da0de11132afc102f94e9296ed))

## [7.0.0](https://github.com/midea-lan/midea-local/compare/midea-local-v6.11.1...midea-local-v7.0.0) (2026-08-05)


### ⚠ BREAKING CHANGES

* **b8:** drop const and align behavior with other devices ([#579](https://github.com/midea-lan/midea-local/issues/579))
* **c3:** drop const in devices ([#577](https://github.com/midea-lan/midea-local/issues/577))

### Features

* **b0:** map mode 0xA1 time defrost in _mode31 ([#570](https://github.com/midea-lan/midea-local/issues/570)) ([514a583](https://github.com/midea-lan/midea-local/commit/514a583c1f8cab1dcf8fb926ac7779234b186607))


### Bug Fixes

* **ac:** expose named speeds for custom fan capability ([#568](https://github.com/midea-lan/midea-local/issues/568)) ([fb5e7d7](https://github.com/midea-lan/midea-local/commit/fb5e7d7b2f1bf16b8ca7e69101722b033a69390b))
* **ac:** make screen_display switch idempotent ([#600](https://github.com/midea-lan/midea-local/issues/600)) ([05e5f95](https://github.com/midea-lan/midea-local/commit/05e5f95f562bd71c57be1f62807320114942677c))
* **ac:** model 22013279 temperature decoding ([#572](https://github.com/midea-lan/midea-local/issues/572)) ([efae776](https://github.com/midea-lan/midea-local/commit/efae776232a2baacd41f7284c17b8ebb30022a57))
* **b0:** assemble cloudmenuid as a big-endian 3-byte value ([#569](https://github.com/midea-lan/midea-local/issues/569)) ([cb3ec5e](https://github.com/midea-lan/midea-local/commit/cb3ec5ecfeecf1dc68926fa03e0de567ba9526b6))


### Code Refactoring

* **b8:** drop const and align behavior with other devices ([#579](https://github.com/midea-lan/midea-local/issues/579)) ([f233f15](https://github.com/midea-lan/midea-local/commit/f233f15c246328275e26b1d52efaf948ccd8e132))
* **c3:** drop const in devices ([#577](https://github.com/midea-lan/midea-local/issues/577)) ([752ef52](https://github.com/midea-lan/midea-local/commit/752ef52e32d40311eb356b15e3bcaa22a88cfc0c))

## [6.11.1](https://github.com/midea-lan/midea-local/compare/v6.11.0...v6.11.1) (2026-07-27)


### Bug Fixes

* **ac:** only decode 0x7e temperatures on subtype-8 devices ([#567](https://github.com/midea-lan/midea-local/issues/567)) ([13d25b9](https://github.com/midea-lan/midea-local/commit/13d25b96a0c74946d05d7efc1033ef69bd7fd20b))
* **ac:** reject invalid subtype-8 temperatures ([#563](https://github.com/midea-lan/midea-local/issues/563)) ([0953364](https://github.com/midea-lan/midea-local/commit/0953364556d813b99bbb6b2651913b3a17a7a944))


### Documentation

* add E2 and AC (0xAC) reference lua plugins ([#564](https://github.com/midea-lan/midea-local/issues/564)) ([61de6e6](https://github.com/midea-lan/midea-local/commit/61de6e6a50e4fe919cc48a5cefa0942a641793f2))

## [6.11.0](https://github.com/midea-lan/midea-local/compare/v6.10.0...v6.11.0) (2026-07-22)


### Features

* **ac:** add group data ([#507](https://github.com/midea-lan/midea-local/issues/507)) ([c8a5a27](https://github.com/midea-lan/midea-local/commit/c8a5a2735a7284ac9eeab7d4e102a8cc1fc03000))
* **ac:** add model-specific airflow and diagnostics ([#502](https://github.com/midea-lan/midea-local/issues/502)) ([c8d1e33](https://github.com/midea-lan/midea-local/commit/c8d1e33eeb54c3d24caeb8ba9caad735776b52d9))
* **ac:** add power saving mode ([#500](https://github.com/midea-lan/midea-local/issues/500)) ([c40b39a](https://github.com/midea-lan/midea-local/commit/c40b39acacd2e8ab129126c6818111ae8f14f81a))
* **ac:** add rate_select (power rate limit / Gen mode) support ([#469](https://github.com/midea-lan/midea-local/issues/469)) ([3e4322d](https://github.com/midea-lan/midea-local/commit/3e4322dfd49ff9cc870e088b4b7a73b467367fdf))
* **e1:** add dishwasher work controls ([#475](https://github.com/midea-lan/midea-local/issues/475)) ([d46f857](https://github.com/midea-lan/midea-local/commit/d46f857722c5b1588fa7ff56545b40d84289b93b))
* **ed:** add soft water machine (subtype 703) support ([#505](https://github.com/midea-lan/midea-local/issues/505)) ([9c11612](https://github.com/midea-lan/midea-local/commit/9c11612a6a13f88c98b560e6ebf3254150e9919f))
* **fa:** add humidify, waterions, display_on_off (AAF10MR, subtype 0) ([#466](https://github.com/midea-lan/midea-local/issues/466)) ([80d67f6](https://github.com/midea-lan/midea-local/commit/80d67f67bc51626f93ce30223263caf04419b072))
* report MAC address ([#488](https://github.com/midea-lan/midea-local/issues/488)) ([cd862d3](https://github.com/midea-lan/midea-local/commit/cd862d39df0dee3a8cb32f9a8d1ec182d86a2840))
* report serial number ([#493](https://github.com/midea-lan/midea-local/issues/493)) ([bef1082](https://github.com/midea-lan/midea-local/commit/bef1082822a5d51b5e5924fc1f26fa089f5ff972))


### Bug Fixes

* **ac:** decode subtype-8 0x7e setpoint and ignore stale C0 temperatures ([#501](https://github.com/midea-lan/midea-local/issues/501)) ([5e8941f](https://github.com/midea-lan/midea-local/commit/5e8941f4869e5603b19d498511e37ecc9e90e1ec))
* **cd:** correct length body ([#509](https://github.com/midea-lan/midea-local/issues/509)) ([9fe2dae](https://github.com/midea-lan/midea-local/commit/9fe2dae1d5f12ec5d7a57013abb7e8d3afa3bf6a))
* **cd:** use 25-byte RSJRAC SET body with tsMax ([#468](https://github.com/midea-lan/midea-local/issues/468)) ([#497](https://github.com/midea-lan/midea-local/issues/497)) ([54f253d](https://github.com/midea-lan/midea-local/commit/54f253d18c5c53dccda76796cbb7d2bfb3f51435))
* **ce:** remove the quote from the attribute definition ([#508](https://github.com/midea-lan/midea-local/issues/508)) ([dc741e8](https://github.com/midea-lan/midea-local/commit/dc741e82a2cb31eeb7a6bc85a42130f03ecb68b9))
* **dc:** correct progress value comparison ([#515](https://github.com/midea-lan/midea-local/issues/515)) ([aa3cdfe](https://github.com/midea-lan/midea-local/commit/aa3cdfecb6ac819203ace6bb4a1870ae2e4090a5))
* **discovery:** deprecation for XML Element ([#513](https://github.com/midea-lan/midea-local/issues/513)) ([e996a98](https://github.com/midea-lan/midea-local/commit/e996a98447bdd7e695f2edbc748fb6dfc73694a6))
* **e2:** removed trailing comma ([#512](https://github.com/midea-lan/midea-local/issues/512)) ([ae7fd06](https://github.com/midea-lan/midea-local/commit/ae7fd067577ec1c6345671e8d35b680103b891e4))
* **e6:** renamed temperature wrong attributes ([#511](https://github.com/midea-lan/midea-local/issues/511)) ([54ee680](https://github.com/midea-lan/midea-local/commit/54ee6803ad859e3a7777f873528b62cdfc165fc6))
* ignore messages shorter than the header in pre_process_message ([#503](https://github.com/midea-lan/midea-local/issues/503)) ([cf3b106](https://github.com/midea-lan/midea-local/commit/cf3b10671b2134261b0a181ac2f9f2d256b54594))
* increase device query command response timeout value ([#496](https://github.com/midea-lan/midea-local/issues/496)) ([2d3dd6e](https://github.com/midea-lan/midea-local/commit/2d3dd6e91d3cc857d03b733d2f89687743c9e446))
* resolve TCP/UDP socket leaks and improve thread loop termination  ([#476](https://github.com/midea-lan/midea-local/issues/476)) ([8983598](https://github.com/midea-lan/midea-local/commit/89835989e62fb7d442a1eebb7ede222367f458cb))
* **x26:** handle missing fields in some body_types ([#510](https://github.com/midea-lan/midea-local/issues/510)) ([a817a87](https://github.com/midea-lan/midea-local/commit/a817a87ec432bdd9c823dd46300a90829b12f4e5))


### Documentation

* add AGENTS.md as canonical AI agent instructions ([#489](https://github.com/midea-lan/midea-local/issues/489)) ([bb3370e](https://github.com/midea-lan/midea-local/commit/bb3370eff7298fc2d36242f269decb2f6df5d436))

## [6.10.0](https://github.com/midea-lan/midea-local/compare/v6.9.0...v6.10.0) (2026-06-27)


### Features

* **ac:** decode B5 capabilities into feature flags ([#481](https://github.com/midea-lan/midea-local/issues/481)) ([f6b2650](https://github.com/midea-lan/midea-local/commit/f6b26501fbf272c3dda6b6a2e3ff597571b42b2c))

## [6.9.0](https://github.com/midea-lan/midea-local/compare/v6.8.0...v6.9.0) (2026-06-25)


### Features

* **ac:** expose per-mode min/max temperature from B5 capability ([#478](https://github.com/midea-lan/midea-local/issues/478)) ([a558dcd](https://github.com/midea-lan/midea-local/commit/a558dcdcc53e9b7b42b49149c808b4c080894074))
* **e2:** add memory (Memo U) attribute support ([#477](https://github.com/midea-lan/midea-local/issues/477)) ([d9c1f14](https://github.com/midea-lan/midea-local/commit/d9c1f14710d8949d3e8d79dff3462c24774c9818))
* **e2:** support heating power multiplier ([#473](https://github.com/midea-lan/midea-local/issues/473)) ([b732b5a](https://github.com/midea-lan/midea-local/commit/b732b5a5b77a09244bbecc55c9fd000d103c2a5d))


### Bug Fixes

* use asyncio.Lock() instead of threading.Lock() ([#482](https://github.com/midea-lan/midea-local/issues/482)) ([eb4fd26](https://github.com/midea-lan/midea-local/commit/eb4fd26f94a8173f1e29775179234b8079acbe02))

## [6.8.0](https://github.com/midea-lan/midea-local/compare/v6.7.2...v6.8.0) (2026-06-16)


### Features

* **ac:** reflect self-clean running state from device report ([#467](https://github.com/midea-lan/midea-local/issues/467)) ([d77be26](https://github.com/midea-lan/midea-local/commit/d77be2686e09792d94dcaa06200ddf616f5232be))

## [6.7.2](https://github.com/midea-lan/midea-local/compare/v6.7.1...v6.7.2) (2026-06-07)


### Bug Fixes

* **ci:** update release deploy job needs commitlint ([#462](https://github.com/midea-lan/midea-local/issues/462)) ([47e9984](https://github.com/midea-lan/midea-local/commit/47e9984959f26c1afca10ce58494fb3732a3ee32))

## [6.7.1](https://github.com/midea-lan/midea-local/compare/v6.7.0...v6.7.1) (2026-06-06)


## [6.7.0](https://github.com/midea-lan/midea-local/compare/v6.6.2...v6.7.0) (2026-06-06)


### Features

* **a1:** add dehumidifier pump state and control ([#446](https://github.com/midea-lan/midea-local/issues/446)) ([91c3dde](https://github.com/midea-lan/midea-local/commit/91c3dde22f1c06bda808f413273ca9fff2c97f78)), closes [#445](https://github.com/midea-lan/midea-local/issues/445)
* **ac:** add anion, sound, self_clean, pmv and error_code support ([#444](https://github.com/midea-lan/midea-local/issues/444)) ([e763077](https://github.com/midea-lan/midea-local/commit/e763077bec37afe158c3efb67c43accbf8e9a5c6))
* **ac:** add out_silent (outdoor silent mode) support for PortaSplit ([#441](https://github.com/midea-lan/midea-local/issues/441)) ([9af1ad9](https://github.com/midea-lan/midea-local/commit/9af1ad99a0c22e34d29a268e1d4d57d25d844a2c))
* **ac:** support mixed C1 power analysis ([#447](https://github.com/midea-lan/midea-local/issues/447)) ([5824a68](https://github.com/midea-lan/midea-local/commit/5824a689d083fdbb18e733811634ae902fe16f6d))
* **cc:** support 0xFE VRF panel protocol (171PNL01/171PANEL) ([#448](https://github.com/midea-lan/midea-local/issues/448)) ([c77aeef](https://github.com/midea-lan/midea-local/commit/c77aeefe188e4d7523bf133b7ee94a64d24a6262))
* **cd:** add vacation mode/sterilize/schedule and avoid corrupted body/max_temp issue ([#429](https://github.com/midea-lan/midea-local/issues/429)) ([fb30bd6](https://github.com/midea-lan/midea-local/commit/fb30bd6ba0724a6b407f4215dd0cec750e526954))


### Bug Fixes

* skip failed to decrypt device message ([#431](https://github.com/midea-lan/midea-local/issues/431)) ([2f464d0](https://github.com/midea-lan/midea-local/commit/2f464d00c14fc57039b17df724ec2643901d8ba1))

## [6.6.2](https://github.com/midea-lan/midea-local/compare/v6.6.1...v6.6.2) (2026-05-23)


### Bug Fixes

* common_regex warning with python3.14 during HA restart ([#430](https://github.com/midea-lan/midea-local/issues/430)) ([13904a9](https://github.com/midea-lan/midea-local/commit/13904a9e7b37bb9750b677f0a4201975bf133f92))
* mypy check bytes and bytearray error ([#432](https://github.com/midea-lan/midea-local/issues/432)) ([7dc5816](https://github.com/midea-lan/midea-local/commit/7dc5816fe830f58dc66ad5b908e8cf230ba9d201))

## [6.6.1](https://github.com/midea-lan/midea-local/compare/v6.6.0...v6.6.1) (2026-05-23)


### Bug Fixes

* make unregister update method public ([#433](https://github.com/midea-lan/midea-local/issues/433)) ([026cac3](https://github.com/midea-lan/midea-local/commit/026cac379edcb29548c5d8a4fb2097b3219c9c16))

## [6.6.0](https://github.com/midea-lan/midea-local/compare/v6.5.0...v6.6.0) (2026-02-18)


### Features

* **a1:** add filter cleaning reminder attribute ([#419](https://github.com/midea-lan/midea-local/issues/419)) ([648febb](https://github.com/midea-lan/midea-local/commit/648febb138f66978e61a40150929dfc21d63676c))
* add dehumidifier (A1) filter cleaning reminder attribute to ([648febb](https://github.com/midea-lan/midea-local/commit/648febb138f66978e61a40150929dfc21d63676c))
* **c3:** add water inlet/outlet temperature and current power sensors ([#418](https://github.com/midea-lan/midea-local/issues/418)) ([8cef9f4](https://github.com/midea-lan/midea-local/commit/8cef9f4da6059f90cd0baec9f1ac647d18a1d53b)), closes [#510](https://github.com/midea-lan/midea-local/issues/510)
* **doc:** add contributing guide docs ([#413](https://github.com/midea-lan/midea-local/issues/413)) ([3d7e1e8](https://github.com/midea-lan/midea-local/commit/3d7e1e8881a2ecb56f6a1e73ed7353a51432fd5c))


### Bug Fixes

* **ac:** allow half-degree integer temperatures ([#412](https://github.com/midea-lan/midea-local/issues/412)) ([95ba499](https://github.com/midea-lan/midea-local/commit/95ba499551ce794d5d99ddccef99c34deb5755ba))
* **ac:** refactor to add new binary power format ([#411](https://github.com/midea-lan/midea-local/issues/411)) ([ba39f10](https://github.com/midea-lan/midea-local/commit/ba39f104d8cb33c856fcf8de6a74772e99772736))
* **ac:** resolve mode change failure when transitioning from DRY mode ([#422](https://github.com/midea-lan/midea-local/issues/422)) ([e31e46f](https://github.com/midea-lan/midea-local/commit/e31e46f68b02823d82ce75d5bb4b4fe36ab4642a))
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
