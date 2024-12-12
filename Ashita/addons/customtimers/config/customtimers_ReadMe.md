
# CustomTimers Addon - ReadMe

## Section 1: In-Game Commands

This addon allows for managing multiple timers and stopwatches in-game. Below are detailed instructions for all available commands:

### Timer Commands

1. **Start a Timer Using XML Configuration:**
   - **Command:** `/tim start [TimerName]`
   - **Example:** `/tim start TimerOne`
   - **Description:** Starts a timer with the specified name using the attributes from the `settings.xml` file, including duration, position, color, and notifications. If the timer name is not found in `settings.xml`, the timer will start using default settings.

2. **Start a Custom Timer (Not in XML):**
   - **Command:** `/tim start [TimerName] [duration] [x_position] [y_position]`
   - **Examples:** 
     - `/tim start MyTimer 15m`
     - `/tim start MyTimer 30s 100x 200y`
     - `/tim start MyTimer 5m 150x`
   - **Description:** Starts a custom timer with a specified duration.  E.G. `15m` for 15 minutes or `30s` for 30 seconds but both `s` and `m` should not be specified. For 1.5 minutes you would need to specify `90s` The x and y parameters are optional and set the screen position of the timer. If x and y are not specified, the timer will use default positioning. This timer does not need to be defined in `settings.xml`.

3. **Stop a Specific Timer:**
   - **Command:** `/tim stop [TimerName]`
   - **Example:** `/tim stop TimerOne`
   - **Description:** Stops a specific timer by name. If the timer is not found, a message will be displayed stating that the timer was not found.

4. **Stop All Timers:**
   - **Command:** `/tim stop`
   - **Description:** Stops all active timers. This will remove any running timers, whether custom or from the XML configuration, from the screen.

### Stopwatch Commands

1. **Start a Stopwatch Using XML Configuration:**
   - **Command:** `/sw start [StopwatchName]`
   - **Example:** `/sw start StopwatchOne`
   - **Description:** Starts a stopwatch with the specified name using attributes from `settings.xml`. If the name is not found, the stopwatch will start using default settings.

2. **Start a Custom Stopwatch (Not in XML):**
   - **Command:** `/sw start [StopwatchName] [x_position] [y_position]`
   - **Example:** `/sw start CustomStopwatch 150x 250y`
   - **Description:** Starts a custom stopwatch with specified x and y screen coordinates. This stopwatch does not need to be defined in `settings.xml` and will use the provided parameters or defaults if not specified.

3. **Stop a Specific Stopwatch:**
   - **Command:** `/sw stop [StopwatchName]`
   - **Example:** `/sw stop StopwatchOne`
   - **Description:** Stops a specific stopwatch by name. If the stopwatch is not found, a message will display indicating it was not found.

4. **Stop All Stopwatches:**
   - **Command:** `/sw stop`
   - **Description:** Stops all active stopwatches, clearing them from the screen.

### General Commands

1. **Stop All Timers and Stopwatches:**
   - **Command:** `/tim kill`
   - **Description:** Stops all active timers and stopwatches at once, removing them from the screen.

2. **Test Sound Notification:**
   - **Command:** `/tim soundtest`
   - **Description:** Plays a test sound notification to confirm that audible notifications are functioning. The sound file is located at `resources/A timer has ended.wav`.

3. **Display Help and Command Overview:**
   - **Command:** `/tim help`
   - **Description:** Displays a help message listing all available commands and their usage.

4. **Invalid Command Response:**
   - If an invalid command is entered (e.g., `/tim asdfasdf`), the addon will display an error message stating that the command is unrecognized and will automatically show the help menu.

## Section 2: Overview of settings.xml

The `settings.xml` file configures the default behaviors and predefined attributes for timers and stopwatches. This file allows you to define:

1. **Default Settings for Timers and Stopwatches**:
   - Default font size, color, position, duration, and audible notification settings. These apply to any timer or stopwatch without explicit settings.

2. **Predefined Timers and Stopwatches**:
   - Named timers and stopwatches with custom settings can be defined here, including font size, RGB color, screen position, and duration. Named timers and stopwatches in `settings.xml` enable easy access using only their names (e.g., `/tim start TimerOne`), making them convenient for frequently used timers.

Any custom timer or stopwatch not defined in `settings.xml` will rely on either the parameters provided in the command or the default settings in `settings.xml`, allowing flexibility for both pre-planned and ad-hoc time management.

---

This document provides a comprehensive overview of all available commands and the purpose of the `settings.xml` file in the `customtimers` addon.
