# Echoes Under Blossoms

[简体中文](./README.zh_Hans.md) [日本語](/README.ja.md)

HanaShirabe is the romanized abbreviation of the Japanese phrase "花隠れの調べ (Hanakakure no Shirabe)", used to describe our web application. For English users, we refer to it as **Echoes Under Blossoms**.

A platform for excavating rarely circulated works from Visual Novels / Galgames or other media.

## Mission and Inspiration

> _Leave proof of having lived_
>
> —— Mai Mai Mai Mai Miao

Inspired by the work of [Mai Mai Mai Mai Miao](https://space.bilibili.com/3494356619102794).
They are dedicated to unearthing buried obscure music, especially lost works from Japanese VN/Galgame.
Videos often focus on tracks where the author has disappeared and the source is hard to trace.

In addition to Mai Mai Mai Mai Miao, [HachimiWorld](https://github.com/HachimiWorld)[^hachimi] as a meme-driven community is also a source of inspiration. We thus create a systematic, community-based platform, allowing more users to participate in excavation and re-creation, rather than limited to individual sharing.

[^hachimi]: This organization focuses on developing a community-driven open-source meme culture music community.

## Features and Highlights

### Core Domain Objects

- **Proposal**
  - Users initiate excavation proposals for specific games, providing clues (such as historical records, author contacts) to help recover lost audio
  - Proposals have a lifecycle: Creation → Resource Gathering → Excavation → Validation → Closure/Abandonment → Supplementation
    - This also involves searching for authors and developers
  - Generally contributed by one or more users with clues, verified in an observational manner by other users and administrators (Spectators)
- **Audio Resource**
  - The main object of the proposal is the audio resource
  - Includes metadata of music tracks (composer, work, format, etc.)
  - Generally provides external links or the file itself (depending on available information)
  - Resources are associated with games, supporting search and re-creation
  - Re-creation and interpretation of audio resources involve the audio resource itself

Regarding authors and vendors, since many are lost and hard to retrieve, they will not be considered as **primary** business objects [this point needs discussion].

### Copyright

This project is for educational and research purposes only and does not encourage any infringement.
All audio resources must obtain author permission or comply with fair use.
The platform does not host unauthorized files; users are responsible for the compliance of uploaded content.
We reference community practices like [Lost Media Wiki](https://lostmediawiki.com/Home), emphasizing information sharing rather than distribution.

If there are copyright issues, please contact the administrator for removal.
If you are a composer or rights holder, welcome to contact us to authorize sharing your works!

## Technology Stack

- Backend: Elixir + Phoenix
- Interaction: Phoenix LiveView
- Database: SQLite
- Frontend: Tailwind CSS + DaisyUI

## Contributions

Welcome VN / Galgame enthusiasts and developers to participate! Contribution methods:

- Submit Issues: Report bugs or suggest new features
- New Features: Implement new proposal lifecycle events or UI components
- Submit Translations: We need Japanese translations!
- Content Contributions: After the platform launches, create proposals to share clues

## Contact Us

- GitHub: https://github.com/GES233/EchoesUnderBlossoms

Thank you for your attention, let's rediscover lost notes under the flower shadows together!
