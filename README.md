# Gold Silver Translation — Shosetsu extension

A small Shosetsu repository containing an extension for:

- **Site:** https://goldsilvertranslation.wordpress.com/
- **Novel:** *Douluo Dalu 4: Ultimate Fighting* (DD4)

## Why it uses the WordPress API

Gold Silver Translation's visible `Douluo Dalu 4 – Chapter List` page is stale and stops in the 300s. The extension therefore reads the site's public WordPress.com posts API, filters posts whose titles begin with a chapter number, and builds the chapter list dynamically. New chapters should appear when Shosetsu refreshes the novel.

The extension is self-contained and does **not** require a separate Lua library repository.

## Easiest installation: host this folder on GitHub

Shosetsu repositories need to be reachable over HTTP; it cannot use this ZIP directly as a permanent repository URL.

1. Create a new **public** GitHub repository, for example `shosetsu-goldsilver`.
2. Upload the contents of this folder to the repository root, preserving this layout:

   ```text
   index.json
   README.md
   src/
     en/
       GoldSilverTranslation.lua
   ```

3. In Shosetsu, go to **More → Repositories → +**.
4. Give it a name such as `GoldSilver`.
5. Use this repository URL, replacing `YOUR_USERNAME`:

   ```text
   https://raw.githubusercontent.com/YOUR_USERNAME/shosetsu-goldsilver/main/
   ```

6. Refresh Shosetsu's repositories/extensions list.
7. Install **Gold Silver Translation**.
8. Open the extension and select **Douluo Dalu 4: Ultimate Fighting**.

## Updating

You should not need to edit the extension as new DD4 chapters are posted. The chapter list is generated from the live WordPress.com API each time Shosetsu refreshes the novel.

## Notes

- Gold Silver's translation begins at chapter **269**, so earlier chapters are intentionally excluded.
- The site currently contains well over 900 translated chapter posts. The extension paginates the API in batches of 100 and stops when WordPress returns the final short page.
- If Gold Silver changes its site platform or chapter-title format, the parser may need an update.
