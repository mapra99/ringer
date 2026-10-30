# ringer

Place phone calls from the macOS Phone app on a schedule, and have your Mac speak a message once someone picks up.

```sh
ringer schedule +15551234567 06:00 06:10 06:20 -m "Good morning! Time to get up for your flight."
```

At each of those times ringer dials the number through your iPhone, waits for the call to be answered, says the message a few times and hangs up. If nobody answers within a minute it gives up on that call and waits for the next one.

It started as a way to wake someone up for an early flight after I'd fallen asleep.

## Requirements

- macOS 26 (Tahoe) or later, which has the Phone app. Tested on 26.4.
- An iPhone on the same Apple ID and Wi-Fi network, with **Settings > Phone > Calls on Other Devices** turned on for your Mac.
- [SwitchAudioSource](https://github.com/deweller/switchaudio-osx) (`brew install switchaudio-osx`).
- A speaker and a microphone that can hear it, plus a second audio output for the call itself. See [How the audio works](#how-the-audio-works).
- Optional: `ffmpeg`, which `ringer setup` uses to check that the mic hears the speaker.
- iTerm2 or Terminal.app. Other terminals work too, but scheduled calls then wait in the same window (`--here`).

## Install

With Homebrew:

```sh
brew install mapra99/tap/ringer
```

Or copy the script anywhere on your `PATH`:

```sh
curl -fsSL https://raw.githubusercontent.com/mapra99/ringer/main/bin/ringer -o /usr/local/bin/ringer
chmod +x /usr/local/bin/ringer
brew install switchaudio-osx
```

## Setup

```sh
ringer setup
```

Setup asks for Accessibility permission for your terminal app, since ringer presses the Call and End buttons through macOS accessibility. Then you pick a microphone, the speaker that plays the message and the output for the call's audio. It plays a test phrase and measures how loud the mic heard it, then saves everything to `~/.config/ringer/config`.

Make a test call to your own phone before relying on it:

```sh
ringer call +15551234567 "This is a test"
```

Calling your own iPhone sends you straight to voicemail, which still counts as answered, so you'll find the message in your voicemail. A second phone you can pick up gives a better test.

`ringer doctor` checks permissions, devices and config whenever something seems off.

## Usage

```sh
ringer call <number> [message] [options]     # call now
ringer schedule <number> <time>... [options] # call at each time
ringer list                                  # show scheduled calls
ringer cancel <id> | --all                   # cancel them
ringer log -f                                # follow the log
```

Without a message, ringer only dials. It presses Call and leaves the call to you, using your normal mic and speakers:

```sh
ringer call +15551234567                  # dial, then you talk
ringer call +15551234567 "Hola, ya llegué" # dial, say this when answered, hang up
```

For `schedule`, pass the message with `-m` or `-f`, since the extra arguments are times.

Times are `HH:MM`, meaning the next time the clock reads that, or `"YYYY-MM-DD HH:MM"`. Add `--date YYYY-MM-DD` to pin bare times to a specific day.

| Option | |
| --- | --- |
| `-m, --message TEXT` | Say `TEXT` once the call is answered. |
| `-f, --message-file FILE` | Say the contents of `FILE` once the call is answered. |
| `-v, --voice NAME` | Any voice from `say -v '?'`, such as `Paulina` for Mexican Spanish. |
| `-r, --repeat N` | Say the message `N` times (default 3). |
| `-t, --timeout SECS` | Seconds to wait for an answer (default 60). |
| `--here` | `schedule` only. Wait in the current terminal instead of opening a window. |

When you schedule calls, ringer opens a new iTerm2 or Terminal window that waits for each time and makes the calls. **Leave that window open.** Closing it cancels the remaining calls. It keeps the Mac and display awake until the last call.

## How the audio works

The Phone app routes calls through your iPhone, but the audio goes through the Mac. ringer can't feed sound into the call directly. So it plays the message out loud on one speaker and lets a microphone carry it into the call.

The message speaker has to be a **different output** from the one the call uses. During a call, macOS turns down other sounds on the call's output and runs echo cancellation against them, and the other side hears nothing. A setup that works:

- microphone: a USB mic, or the MacBook's built-in one with the lid open
- message speaker: an external or Bluetooth speaker next to that mic
- call audio: the MacBook speakers

A virtual loopback device such as BlackHole looks like the obvious answer. In testing, the Phone app didn't pass its audio through to the call.

## Things to know

- **The Mac has to stay unlocked.** Accessibility can't press buttons on a locked screen. Turn off "Start Screen Saver when inactive" while calls are scheduled. ringer keeps the display awake, but some setups lock anyway.
- **A closed lid turns off the built-in mic** on Apple Silicon MacBooks. Use an external mic or leave the lid open. With the lid closed, the Mac only stays awake while an external display is connected and on.
- **A VPN on the Mac or the iPhone** breaks Continuity calls with "Call Failed". ringer retries a failed call up to 3 times.
- **Bluetooth headsets** take over the call's microphone when a call starts. Turn them off.
- **English UI only, for now.** ringer finds the Call and End buttons by their labels. On another system language, set `ui_call_button` and `ui_end_button` in the config to the labels your Mac shows.
- **Answer detection reads the call timer** in the call banner. Voicemail answering also starts the timer, so the message gets recorded there.

## Use it responsibly

Only call people who expect it. Automated calls with recorded or synthetic voices are regulated in many places, the US TCPA among them. ringer is meant for personal reminders and wake-up calls, never for telemarketing.

## Development

```sh
zsh test/run.zsh
```

The tests cover number parsing, times, config and options. Anything that dials needs a real Mac, an iPhone and a second phone to answer.

## License

MIT
