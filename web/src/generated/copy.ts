// GENERATED FILE — DO NOT EDIT. Source: shared/copy/*.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: A16.a · 6.6 — user-facing copy shared by both platforms; placeholders already resolved from spec-constants.

export type WhisperId = "why.ppl" | "how.revealSwap" | "how.swapSkip" | "why.streak" | "how.invite" | "why.crews" | "how.quickComplete" | "how.pause" | "how.overload" | "why.protein" | "why.freeDinner" | "how.shake";
export const whisperIds: WhisperId[] = ["why.ppl", "how.revealSwap", "how.swapSkip", "why.streak", "how.invite", "why.crews", "how.quickComplete", "how.pause", "how.overload", "why.protein", "why.freeDinner", "how.shake"];
export interface CopySource { id: string; label: string; url: string }
export interface NutritionMethodStep { heading: string; body: string; sourceIds: string[] }
export interface NutritionMethodCopy { title: string; lead: string; steps: NutritionMethodStep[]; clinician: string; sources: CopySource[] }
export type CopyGate = "all" | "adult"; // adult = behind the 18+ nutrition gate (A16.c)
export interface EducationWhisper { id: WhisperId; line: string; moment: string; gate: CopyGate }
export interface EducationSource { label: string; url: string; gate: CopyGate }
export interface EducationSection { id: string; heading: string; body: string; adultBody: string; source: EducationSource | null }
export interface EducationPage { title: string; note: { draft: boolean; heading: string; body: string }; sections: EducationSection[]; whispersHeading: string; clinician: string }
export interface EducationCopy { whispers: EducationWhisper[]; page: EducationPage }
export interface LegalSection { heading: string; paragraphs: string[] }
export interface LegalDocument { title: string; lead: string; sections: LegalSection[] }
export interface LegalCopy { updated: string; privacy: LegalDocument; terms: LegalDocument }

export const nutritionMethod: NutritionMethodCopy = {
  "title": "How targets are estimated",
  "lead": "Your targets start from one number, your bodyweight. Everything here is an estimate, and you can overwrite any of it in Nutrition targets.",
  "steps": [
    {
      "heading": "Energy",
      "body": "Bodyweight in kilograms × 33 kcal, rounded to the nearest 50. It's a maintenance estimate for someone who trains a few days a week. It's never a deficit and never a surplus.",
      "sourceIds": [
        "kerksick2018"
      ]
    },
    {
      "heading": "Protein",
      "body": "Bodyweight in kilograms × 1.8 g. Protein is set first, and the other two fit around it.",
      "sourceIds": [
        "jager2017"
      ]
    },
    {
      "heading": "Fat",
      "body": "20% of the energy estimate, and never less than 0.5 g per kilogram of bodyweight.",
      "sourceIds": [
        "iom2005"
      ]
    },
    {
      "heading": "Carbs",
      "body": "The energy left after protein and fat, never below zero.",
      "sourceIds": []
    },
    {
      "heading": "Calories",
      "body": "Counted from grams: 4 kcal per gram of protein, 4 per gram of carbs, 9 per gram of fat. Today's calorie line adds up your three gram targets this way, so it can sit a little off the energy estimate.",
      "sourceIds": [
        "fao2003"
      ]
    },
    {
      "heading": "Rounding",
      "body": "Grams round to the nearest 5, so an estimate never reads like a measurement.",
      "sourceIds": []
    }
  ],
  "clinician": "These are estimates and rules of thumb, not medical advice. Talk to a clinician before acting on them. Every source above is a link.",
  "sources": [
    {
      "id": "kerksick2018",
      "label": "Kerksick et al., ISSN exercise & sports nutrition review update: research & recommendations. Journal of the International Society of Sports Nutrition, 2018.",
      "url": "https://doi.org/10.1186/s12970-018-0242-y"
    },
    {
      "id": "jager2017",
      "label": "Jäger et al., International Society of Sports Nutrition Position Stand: protein and exercise. Journal of the International Society of Sports Nutrition, 2017.",
      "url": "https://doi.org/10.1186/s12970-017-0177-8"
    },
    {
      "id": "iom2005",
      "label": "Institute of Medicine, Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids. National Academies Press, 2005.",
      "url": "https://www.nationalacademies.org/publications/10490"
    },
    {
      "id": "fao2003",
      "label": "FAO, Food energy — methods of analysis and conversion factors (Food and Nutrition Paper 77), chapter 3. 2003.",
      "url": "https://www.fao.org/4/y5022e/y5022e04.htm"
    }
  ]
};
export const education: EducationCopy = {
  "whispers": [
    {
      "id": "why.ppl",
      "line": "Push, pull, legs: three days, every muscle covered, no decisions.",
      "moment": "the plan reveal",
      "gate": "all"
    },
    {
      "id": "how.revealSwap",
      "line": "Tap any exercise to swap it.",
      "moment": "the plan reveal",
      "gate": "all"
    },
    {
      "id": "how.swapSkip",
      "line": "Machine's taken? Swap. Wrecked? Skip. Both are fine.",
      "moment": "the first workout",
      "gate": "all"
    },
    {
      "id": "why.streak",
      "line": "The flame counts days you showed up, not effort.",
      "moment": "the first lit flame",
      "gate": "all"
    },
    {
      "id": "how.invite",
      "line": "Send the link or the code straight into your group text.",
      "moment": "the first Invite screen",
      "gate": "all"
    },
    {
      "id": "why.crews",
      "line": "Four people who know you beat any algorithm.",
      "moment": "the first crew on the Crew tab",
      "gate": "all"
    },
    {
      "id": "how.quickComplete",
      "line": "Trained phone-free? Quick complete logs today at your targets.",
      "moment": "the first Quick complete offer",
      "gate": "all"
    },
    {
      "id": "how.pause",
      "line": "Away a while? Pause the plan. The streak stays whole.",
      "moment": "the first Settings Plan group",
      "gate": "all"
    },
    {
      "id": "how.overload",
      "line": "Add a rep before you add weight.",
      "moment": "the first row that remembers last time",
      "gate": "all"
    },
    {
      "id": "why.protein",
      "line": "Protein's planned first: the hardest number on a busy day.",
      "moment": "the first nutrition targets",
      "gate": "adult"
    },
    {
      "id": "why.freeDinner",
      "line": "Same foods by day, dinner's yours. Fewer decisions, honest tracking.",
      "moment": "the first daily template",
      "gate": "adult"
    },
    {
      "id": "how.shake",
      "line": "Morning scoop? It's a template slot. One tap logs it.",
      "moment": "the first template slot",
      "gate": "adult"
    }
  ],
  "page": {
    "title": "How Crew works",
    "note": {
      "draft": true,
      "heading": "A note from Max",
      "body": "I work a full-time job and I still want to train well. This is how I actually train: three days, push, pull, legs, the same breakfast and lunch, a dinner I look forward to. Crew is the plan I follow — nothing in here I don't do myself. If it gets you through one full week, that's the whole point."
    },
    "sections": [
      {
        "id": "ppl",
        "heading": "Push, pull, legs",
        "body": "It's simple: three days, one job each, no decisions at the rack. It's balanced — every major muscle gets its day — and efficient, because you're never waiting on a pattern you trained yesterday. Recovery is built in: one group rests while the next day works another. A plan you'll follow beats a perfect one you won't; when you're ready, add a fourth day and every muscle gets hit more often.",
        "adultBody": "",
        "source": {
          "label": "Schoenfeld, Ogborn & Krieger, Effects of Resistance Training Frequency on Measures of Muscle Hypertrophy. Sports Medicine, 2016.",
          "url": "https://doi.org/10.1007/s40279-016-0543-8",
          "gate": "all"
        }
      },
      {
        "id": "protein",
        "heading": "Protein first",
        "body": "Protein is planned first because it's the hardest number to hit on a busy day. It keeps you full, and muscle needs it to repair and grow. If you track one number, track this one.",
        "adultBody": "A working range is 0.7–1 g per pound of bodyweight; 1 g per pound is the easy target to remember.",
        "source": {
          "label": "Morton et al., A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains in muscle mass and strength in healthy adults. British Journal of Sports Medicine, 2018.",
          "url": "https://doi.org/10.1136/bjsports-2017-097608",
          "gate": "adult"
        }
      },
      {
        "id": "sameFoods",
        "heading": "Same foods, free dinner",
        "body": "Eating the same breakfast and lunch removes decisions from the busiest part of the day. Dinner is the reward: it changes, you enjoy it, and you still know your numbers. Tracking stays honest because most of the day is already logged. Prep is cheaper, too — the same groceries, fewer of them wasted.",
        "adultBody": "",
        "source": null
      },
      {
        "id": "streak",
        "heading": "The streak",
        "body": "Showing up is the whole game. The flame counts days, not effort — a light day and a big day light it the same.",
        "adultBody": "",
        "source": null
      },
      {
        "id": "crews",
        "heading": "Crews",
        "body": "Four people who know you beat any algorithm. Your crew sees you show up and reacts; that's it — no feed, no chat, no scores. Two to ten friends, one link or code.",
        "adultBody": "",
        "source": null
      },
      {
        "id": "mobility",
        "heading": "Mobility",
        "body": "Five to ten minutes of holds at the end of a workout keeps you moving without a separate session. They're part of the plan, so they get done.",
        "adultBody": "",
        "source": null
      },
      {
        "id": "rest",
        "heading": "Rest days",
        "body": "Growth happens between workouts. Rest is part of the plan, not a gap in it.",
        "adultBody": "",
        "source": null
      }
    ],
    "whispersHeading": "What the whispers said",
    "clinician": "These are estimates and rules of thumb, not medical advice. Talk to a clinician before acting on them. Every source above is a link."
  }
};
export const legal: LegalCopy = {
  "updated": "18 September 2026",
  "privacy": {
    "title": "Privacy policy",
    "lead": "Crew is a training app for small groups of friends. This page says what Crew keeps about you, why, who can see it, and how you take it back. There is no public feed, there are no ads, and nothing is sold.",
    "sections": [
      {
        "heading": "What Crew keeps",
        "paragraphs": [
          "Your account: your email address, a password that is stored only as a salted hash, the name you chose, your birth year, your timezone, your unit and reminder preferences, a profile photo if you add one, and a record of which one-time tips you have already seen. If you use Sign in with Apple, Crew keeps the identifier Apple gives it and the email address Apple shares, which may be a private relay address.",
          "Your training: your weekly plan, every workout and cardio session you log with its sets, weights, times and distances, the posts those create and any caption you add, your reactions, your crew membership, any pause you set, and the streak, points and achievements worked out from them.",
          "Nutrition, if you are 18 or older and choose to use it: one current bodyweight, your daily targets, the meals you save, your daily template and what you log. Crew keeps no weight history.",
          "Your device: a push notification token, if you allow notifications.",
          "How the app is used: Crew records its own simple events, such as a plan being built or a workout being completed, in its own database. There are no third-party analytics or advertising tools in Crew.",
          "Safety records: reports you file, and the people you block."
        ]
      },
      {
        "heading": "What Crew does with it",
        "paragraphs": [
          "Crew uses this information to run your plan, to show your crew that you trained, to send the reminders you asked for, to keep accounts secure, and to understand which parts of the app work. It is not used for advertising, and it is not sold or rented to anyone."
        ]
      },
      {
        "heading": "Who can see what",
        "paragraphs": [
          "A post you share is visible only to the members of the crew you shared it with, and a crew holds at most 10 people. A post you keep private is visible only to you. Your crew sees your name, your profile photo, your streak and whether you have posted today.",
          "Nutrition is private. Your bodyweight, your targets, your meals and your logs are never shown to your crew, never appear in a post and never appear on a profile.",
          "Your profile photo is resized and stripped of location data before it is stored, and it is served only to you and to members of your crew."
        ]
      },
      {
        "heading": "The companies that help run Crew",
        "paragraphs": [
          "Crew runs on a small number of service providers that process data only to provide their service: Vercel (hosting and photo storage), MongoDB Atlas (the database), Resend (email), and Apple (Sign in with Apple and push notifications). Your data may be processed in the United States and in other countries where these providers operate.",
          "Crew emails you only about your account: password resets and the confirmation that an account was deleted."
        ]
      },
      {
        "heading": "How long Crew keeps it, and how you take it back",
        "paragraphs": [
          "Crew keeps your information for as long as your account exists. In Settings you can export everything Crew holds about you as one file, delete your nutrition data on its own, or delete your account.",
          "Deleting your account removes your plan, workouts, posts, photos, reactions, nutrition data, reports and tokens from Crew's systems right away. The usage events your account created are kept without any link to you. Backups held by the providers above expire on their own schedules.",
          "Depending on where you live, you may have the right to access, correct, move or delete your information, or to object to how it is used. The tools in Settings do most of this directly; for anything else, write to the address below."
        ]
      },
      {
        "heading": "Age",
        "paragraphs": [
          "Crew is for people 13 and older, and Crew asks for a birth year at signup to check. Nutrition features are available only to people 18 and older. If you believe a child under 13 has an account, write to the address below and it will be removed."
        ]
      },
      {
        "heading": "Security",
        "paragraphs": [
          "Connections to Crew are encrypted. Passwords are stored only as salted hashes, sign-in tokens on the iPhone live in the Keychain, and photos are private files served only after a permission check. No system is perfectly secure; if something goes wrong that affects you, Crew will tell you."
        ]
      },
      {
        "heading": "Changes to this policy",
        "paragraphs": [
          "If this policy changes in a way that matters, Crew will say so in the app before the change takes effect."
        ]
      }
    ]
  },
  "terms": {
    "title": "Terms",
    "lead": "These are the terms for using Crew. They are written to be read. By creating an account you agree to them.",
    "sections": [
      {
        "heading": "Who can use Crew",
        "paragraphs": [
          "You need to be 13 or older to use Crew. Nutrition features are for people 18 and older. You are responsible for your account and for keeping your password to yourself."
        ]
      },
      {
        "heading": "Your content",
        "paragraphs": [
          "What you log and post stays yours. You give Crew permission to store it and to show it to the people you chose to share it with, which is the only way the app can work. You can export or delete it at any time from Settings."
        ]
      },
      {
        "heading": "How to treat other people",
        "paragraphs": [
          "Crews are small groups of people who know each other. Do not harass, threaten or impersonate anyone, do not post content that exposes or sexualises another person, and do not use Crew to break the law. Anyone can report a post or a person and anyone can block a person; reports are read by a person. A Captain can remove a member from their crew.",
          "Content that breaks these rules is removed, and an account that keeps breaking them can be closed."
        ]
      },
      {
        "heading": "Training and nutrition are your call",
        "paragraphs": [
          "Crew is not a medical service. The plans, targets and estimates in the app are general information and not medical advice. Talk to a doctor before starting a training program or changing how you eat, especially if you have a health condition, and stop if something hurts. You train at your own risk."
        ]
      },
      {
        "heading": "The service",
        "paragraphs": [
          "Crew is free. It is a young product: features can change, and the service can be paused or ended. If Crew ever ends, you will get notice and time to export your data.",
          "Crew is provided as it is, without warranties of any kind, to the fullest extent the law allows. To the fullest extent the law allows, Crew is not liable for indirect or consequential losses, or for injuries that result from training."
        ]
      },
      {
        "heading": "Ending it",
        "paragraphs": [
          "You can delete your account at any time in Settings, and that ends these terms for you. Crew can close an account that breaks these terms."
        ]
      },
      {
        "heading": "Changes to these terms",
        "paragraphs": [
          "If these terms change in a way that matters, Crew will say so in the app before the change takes effect. Using Crew after that means you accept the new terms."
        ]
      }
    ]
  }
};
