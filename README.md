# Fuel Alerts

Fuel Alerts is a Garmin Connect IQ data field for the Forerunner 970. It helps
runners follow a fueling and hydration plan by showing reminders based on
elapsed distance or elapsed activity time.

When an event becomes due, the data field:

- displays a full-screen `DataFieldAlert` over the current activity page;
- triggers vibration when supported;
- plays an alert tone when supported;
- marks the event as completed so it only fires once.

The normal data-field page shows the next event, the remaining distance or
time, and the most recently triggered event.

## Supported device

- Garmin Forerunner 970
- Round 454 x 454 display
- Connect IQ API 3.2.0 or newer

## Event configuration

The Connect IQ mobile app exposes one text setting named **Events**.

Example:

```text
4:GEL 160 + WATER;5.5:CARBS;8:GEL 160;T35:SALT;12:GEL 100
```

Rules:

- `4:TEXT` triggers at 4 kilometers.
- `5.5:TEXT` triggers at 5.5 kilometers.
- `T35:TEXT` triggers after 35 elapsed activity minutes.
- Separate events with semicolons.
- Separate each threshold from its message with a colon.
- Messages may contain spaces and `+`.
- Invalid individual entries are ignored.

Time values are expressed in minutes. Decimal values are supported, so
`T1.5` means 1 minute 30 seconds.

## Installation from Connect IQ Store

1. Install **Fuel Alerts** from Connect IQ Store and synchronize the watch.
2. Open the Run activity settings on the watch.
3. Add **Fuel Alerts** to a data screen.
4. Enable Connect IQ data-field alerts for the activity.
5. Configure the event string from the app settings in Connect IQ Store.

Alert permissions and sound/vibration settings are controlled by the watch and
may need to be enabled separately for each activity profile.

## Manual installation

Build the project, then copy `FuelAlert.prg` directly to:

```text
GARMIN/APPS/
```

Do not create a subdirectory. Mobile app settings may not be available for
manually sideloaded builds.

## Data-field alert limitation

Garmin does not allow a data field to dismiss a `DataFieldAlert`
programmatically. Calling `WatchUi.popView()` from a data field causes a
runtime exception. Therefore, alert dismissal and timeout are controlled by
the Garmin system.

In the simulator, use **Simulation > Data Fields > Timeout Alert** when an
alert does not close automatically.

## Build

Requirements:

- Garmin Connect IQ SDK
- A local Connect IQ developer key

Example for PowerShell:

```powershell
monkeyc -f .\monkey.jungle `
  -o .\bin\FuelAlert.prg `
  -y C:\path\to\developer_key `
  -d fr970
```

Export a signed Store package:

```powershell
monkeyc -e `
  -f .\monkey.jungle `
  -o .\bin\FuelAlerts.iq `
  -y C:\path\to\developer_key
```

Signing keys and generated build artifacts are intentionally excluded from
version control.

## Project structure

```text
manifest.xml
monkey.jungle
resources/
  drawables/
  settings/
  strings/
source/
  FuelAlertApp.mc
  FuelAlertField.mc
  FuelAlertView.mc
  FuelEvent.mc
  FuelTextLayout.mc
```

- `FuelAlertApp.mc`: application entry point.
- `FuelAlertField.mc`: event parsing, scheduling, notifications, and normal UI.
- `FuelAlertView.mc`: full-screen alert rendering.
- `FuelEvent.mc`: event model.
- `FuelTextLayout.mc`: one-line/two-line adaptive text layout.
