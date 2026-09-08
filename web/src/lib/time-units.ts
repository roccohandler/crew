// The one file that names time units. Not spec numbers, so not in spec-constants.json; exempt from the
// magic-number rule by name in eslint.config.mjs.
export const TimeUnits = {
  msPerSecond: 1000,
  secondsPerMinute: 60,
  minutesPerHour: 60,
  hoursPerDay: 24,
  daysPerWeek: 7,
  msPerMinute: 60 * 1000,
  msPerHour: 60 * 60 * 1000,
  msPerDay: 24 * 60 * 60 * 1000,
} as const;
