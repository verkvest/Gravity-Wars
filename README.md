# Cindarc

Cindarc is a two-ship gravity artillery game for phones. Shots curve around the planets. Play against the on-device pilot, or pass the phone for a hot-seat match.

It is a rebrand of [Gravity Wars](https://github.com/whyboris/Gravity-Wars) by Boris (MIT, 2020), built with [LÖVE](https://love2d.org/) 11.5 (zlib). The original title is not used for the app.

Bundle id, iOS and Android: `es.verkvest.cindarc`

## Play on a computer

1. Install [LÖVE 11.5](https://love2d.org/).
2. From this directory run `love .`

Drag from your ship to aim. Distance from the ship sets power. **FIRE** launches. **Needle**, **Spread**, and **Fan** change the volley. Licenses are on the main menu.

## Phone builds

GitHub Actions builds both stores from the official engine projects. The game is zipped to `game.love` and fused in.

- `ios-testflight` checks out LÖVE 11.5, drops in the Apple library xcframeworks, and archives the `love-ios` target with Xcode. Export uses automatic App Store signing (`teamID` `38PT254HDZ`) and `xcrun altool` uploads the ipa. The bundle id is registered through the App Store Connect API when it is missing. The App Store Connect *app* record cannot be created by the API.
- `android` checks out `love-android` `11.5a`, embeds `game.love`, and builds an `embedNoRecord` release APK and AAB with `targetSdk` 36.

Landscape only. Touch controls sit inside the safe area.

## Credits

See `THIRD_PARTY_LICENSES.txt` and the in-game Licenses screen. Ship sprites and the original rules are Boris's. The typeface is basis33 (Tristan Grimmer, Manchson, MIT).
