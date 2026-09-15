-- {"id":94621784,"ver":"1.0.0","libVer":"1.0.0","author":"OpenAI","repo":"","dep":[]}

local id = 94621784
local baseURL = "https://tri-hermes.org"

-- TRI-HERMES hosts the translated source on GitHub. Reading GitHub's rendered
-- Markdown is intentional: its Camo image mirror keeps the original cover and
-- inline illustrations available in the UK, where direct Imgur links are
-- currently replaced with a regional-block placeholder.
local githubVolumeBase = "https://github.com/r-grandorder/tri-hermes/blob/main/src/Novels/StrangeFake/Vol-"
local coverBase = "https://raw.githubusercontent.com/AppleFox-read/shosetsu-goldsilver/main/res/fate-strange-fake-vol-"
local volumeCovers = {
    coverBase .. "1.jpg",
    coverBase .. "2.jpg",
    coverBase .. "3.jpg",
    coverBase .. "4.jpg",
    coverBase .. "5.jpg",
    coverBase .. "6.jpg",
    coverBase .. "7.jpg"
}

local translators = {
    "Mew, Food, Reiu, and OtherSideOfSky",
    "Mew, Arai, and OtherSideOfSky",
    "OtherSideOfSky",
    "OtherSideOfSky",
    "OtherSideOfSky",
    "OtherSideOfSky",
    "Comun"
}

local readerCSS = [[
    body { overflow-wrap: break-word; }
    img {
        display: block;
        max-width: 100%;
        height: auto;
        margin: 1.25em auto;
        object-fit: contain;
    }
    .markdown-heading .anchor { display: none; }
    hr { margin: 1.5em 0; }
]]

-- The chapter divisions follow the headings in TRI-HERMES' source files.
-- Keeping the list here makes a Shosetsu refresh fast and avoids downloading
-- all seven very large volume pages just to rebuild unchanged metadata.
local volumes = {
    {
        "Extra: Betrayer",
        "Prologue I: Archer",
        "Prologue II: Berserker",
        "Prologue III: Assassin",
        "Prologue IV: Caster",
        "Prologue V: Rider",
        "Prologue VI: Lancer",
        "Extra: “Observer. Or, Character Creation”",
        "Chapter 1: The War Begins",
        "Prologue VII: Visitor & ●●●●",
        "Afterword",
        "Commentary"
    },
    {
        "Interlude: The Red Riding Hood of Semina Apartments",
        "Chapter 2: Day 0, Midnight",
        "Chapter 3: Day 1, Early Dawn",
        "Chapter 4: Day 1, Before Dawn",
        "Chapter 5: Day 1, Dawn",
        "Chapter 6: Day 1, Noon",
        "Bridging Chapter",
        "Afterword"
    },
    {
        "Extra: “—”",
        "Interlude: The End of Escape",
        "Interlude: The Passion of the Nameless Soldier",
        "Chapter 7: Day 1, Afternoon",
        "Interlude: Watcher",
        "Chapter 8: Day 1, Afternoon",
        "Chapter 9: Day 1, Evening",
        "Interlude",
        "Bridge",
        "Afterword"
    },
    {
        "Interlude: The Membrane of the Commonplace",
        "Chapter 10: Day 2",
        "Interlude: The Boy Does Not Believe in God",
        "Chapter 11: Day 2, Morning",
        "Interlude: Backstage at a Third-Rate Comedy",
        "Chapter 12: Day 2, Daytime",
        "Interlude: The Parade of Treachery",
        "Chapter 13: Day 2, Night",
        "Bridge: One Day, Above the Sky",
        "Afterword"
    },
    {
        "Intro: “—”",
        "Bridge: Rondo of the Outsiders",
        "Chapter 14: Gold and Lions I",
        "Interlude: Mercenary, Assassin, Vampire I",
        "Chapter 15: Gold and Lions II",
        "Interlude: Mercenary, Assassin, Vampire II",
        "Chapter 16: Day 3 — Breaking Dawn and Wakeless Dreams I",
        "Interlude: Mercenary, Assassin, ________",
        "Bridge: One Day, Atop a Building",
        "Afterword"
    },
    {
        "Intro: “—”",
        "Bridge: The Canon of the Demigods, Act 2",
        "Chapter 17: Day 3",
        "Interlude: Mercenary, Assassin, Pale Rider",
        "Chapter 18: As Dream and Reality Are Both Illusion I",
        "Interlude: A Mercenary Is a Free Man I",
        "Chapter 19: As Dream and Reality Are Both Illusion II",
        "Interlude: A Beauty and the Sea; A Girl and a Mercenary",
        "Chapter 20: Fantasy Becomes Reality",
        "Interlude: A Mercenary Is a Free Man II",
        "Bridge: Clink Clank",
        "Afterword"
    },
    {
        "Intro: -----",
        "Bridge chapter: Messara Escardos"
    }
}

local function shrinkURL(url)
    if not url then return "" end
    return url:gsub("^https?://tri%-hermes%.org", "")
end

local function expandURL(url)
    if not url then return baseURL end
    if url:match("^https?://") then return url end
    if url:sub(1, 1) ~= "/" then
        url = "/" .. url
    end
    return baseURL .. url
end

local function volumeLink(volumeNumber)
    return "/Novels/StrangeFake/Vol-" .. tostring(volumeNumber) .. ".html"
end


local function bookTitle(volumeNumber)
    local title = "Fate/strange Fake, Vol. " .. tostring(volumeNumber)
    if volumeNumber == 7 then
        title = title .. " (Partial Translation)"
    end
    return title
end


local function chapterList(volumeNumber)
    local chapters = {}
    local titles = volumes[volumeNumber]

    for segmentNumber, title in ipairs(titles) do
        local link = volumeLink(volumeNumber)
            .. "?segment=" .. tostring(segmentNumber)

        -- The material before the first heading contains each volume's
        -- cover/frontispiece images and belongs with its opening section.
        if segmentNumber == 1 then
            link = link .. "&front=1"
        end

        chapters[#chapters + 1] = NovelChapter {
            order = segmentNumber,
            title = title,
            link = link
        }
    end

    return AsList(chapters)
end


local function volumeNumberFromURL(url)
    local volumeNumber = tonumber((url or ""):match("Vol%-(%d+)%.html"))
    if not volumeNumber or not volumes[volumeNumber] then
        error("Fate/strange Fake: invalid volume address")
    end
    return volumeNumber
end

local function parseChapterAddress(chapterURL)
    local volumeNumber = tonumber((chapterURL or ""):match("Vol%-(%d+)%.html"))
    local segmentNumber = tonumber((chapterURL or ""):match("[?&]segment=(%d+)"))
    local includeFront = (chapterURL or ""):match("[?&]front=1") ~= nil

    if not volumeNumber or not segmentNumber or not volumes[volumeNumber]
        or not volumes[volumeNumber][segmentNumber] then
        error("Fate/strange Fake: invalid chapter address")
    end

    return volumeNumber, segmentNumber, includeFront
end


local function fetchRenderedVolume(volumeNumber)
    local url = githubVolumeBase .. tostring(volumeNumber) .. ".md"
    local doc = GETDocument(url)
    local article = doc:selectFirst("article.markdown-body")

    if not article then
        error("Fate/strange Fake: GitHub did not return the rendered volume")
    end

    return article
end


local function normaliseHeading(title)
    return (title or "")
        :lower()
        :gsub("\194\160", " ")
        :gsub("[^%w]+", "")
end


local function headingKey(element)
    local heading = element:selectFirst("h2, h3")
    if not heading then return nil end
    return normaliseHeading(heading:text())
end


local function extractSegment(article, volumeNumber, segmentNumber, includeFront)
    local children = article:children()
    local targetKey = normaliseHeading(volumes[volumeNumber][segmentNumber])
    local nextTitle = volumes[volumeNumber][segmentNumber + 1]
    local nextKey = nextTitle and normaliseHeading(nextTitle) or nil
    local collecting = includeFront
    local foundTarget = false
    local parts = {}

    for index = 0, children:size() - 1 do
        local child = children:get(index)
        local key = headingKey(child)

        -- Match named headings rather than counting every h2/h3. A few source
        -- files contain empty headings (and one bold subtitle rendered as an
        -- h2 by GitHub), neither of which is a real Shosetsu chapter boundary.
        if foundTarget and nextKey and key == nextKey then
            break
        elseif key == targetKey then
            foundTarget = true
            collecting = true
        end

        if collecting then
            parts[#parts + 1] = child:outerHtml()
        end
    end

    if #parts == 0 or not foundTarget then
        error("Fate/strange Fake: could not find this section in the volume")
    end

    local doc = Document('<div id="shosetsu-passage">' .. table.concat(parts) .. "</div>")
    local passage = doc:selectFirst("#shosetsu-passage")

    -- GitHub adds permalink controls beside every heading. They are useful on
    -- the website but visual noise in a book reader.
    map(passage:select("a.anchor"), function(anchor)
        anchor:remove()
    end)

    -- Remove malformed empty headings present in a handful of the upstream
    -- Markdown files without affecting meaningful in-story subheadings.
    map(passage:select("div.markdown-heading"), function(block)
        if headingKey(block) == "" then
            block:remove()
        end
    end)

    return passage
end


local function parsePassage(chapterURL)
    local volumeNumber, segmentNumber, includeFront = parseChapterAddress(chapterURL)
    local article = fetchRenderedVolume(volumeNumber)
    local passage = extractSegment(article, volumeNumber, segmentNumber, includeFront)

    return pageOfElem(passage, true, readerCSS)
end


local function parseNovel(novelAddress, loadChapters)
    local volumeNumber = volumeNumberFromURL(novelAddress)
    local isPartial = volumeNumber == 7
    local description

    if isPartial then
        description = "TRI-HERMES currently contains only the opening portion of Volume 7, translated by "
            .. translators[volumeNumber]
            .. ". The available sections are retained here with their original formatting. The missing volume illustrations are placeholders in the source itself."
    else
        description = "Complete English fan translation of Volume "
            .. tostring(volumeNumber)
            .. " hosted by TRI-HERMES and translated by "
            .. translators[volumeNumber]
            .. ". Available cover/frontispiece and inline illustrations are retained in their original reading positions."
    end

    local info = NovelInfo {
        title = bookTitle(volumeNumber),
        alternativeTitles = { "Fate/Strange Fake, Volume " .. tostring(volumeNumber) },
        link = volumeLink(volumeNumber),
        imageURL = volumeCovers[volumeNumber],
        language = "English",
        status = isPartial and NovelStatus.PUBLISHING or NovelStatus.COMPLETED,
        authors = { "Ryohgo Narita" },
        artists = { "Shizuki Morii" },
        genres = { "Action", "Fantasy", "Supernatural" },
        description = description,
        chapterCount = #volumes[volumeNumber]
    }

    if loadChapters then
        info:setChapters(chapterList(volumeNumber))
    end

    return info
end


local function listing()
    local books = {}

    for volumeNumber = 1, #volumes do
        books[#books + 1] = Novel {
            title = bookTitle(volumeNumber),
            link = volumeLink(volumeNumber),
            imageURL = volumeCovers[volumeNumber]
        }
    end

    return books
end


return {
    id = id,
    name = "Fate/strange Fake (TRI-HERMES)",
    baseURL = baseURL,
    imageURL = volumeCovers[1],
    hasCloudFlare = false,
    hasSearch = false,
    chapterType = ChapterType.HTML,

    listings = {
        Listing("Novels", false, listing)
    },

    getPassage = parsePassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
