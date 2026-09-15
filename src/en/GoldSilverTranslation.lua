-- {"id":94621783,"ver":"1.2.0","libVer":"1.0.0","author":"OpenAI","repo":"","dep":[]}

local id = 94621783
local baseURL = "https://goldsilvertranslation.wordpress.com"
local apiBase = "https://public-api.wordpress.com/rest/v1.1/sites/goldsilvertranslation.wordpress.com/posts/"
local chapterListURL = "/douluo-dalu-4/"
local pageSize = 100

-- Gold Silver Translation picked up DD4 from chapter 269.
local firstGoldSilverChapter = 269

local function shrinkURL(url)
    if not url then return "" end
    return url:gsub("^https?://goldsilvertranslation%.wordpress%.com", "")
end

local function expandURL(url)
    if not url then return baseURL end
    if url:match("^https?://") then return url end
    if url:sub(1, 1) ~= "/" then
        url = "/" .. url
    end
    return baseURL .. url
end

-- Small self-contained JSON decoder so this extension does not depend on a
-- second custom repository/library. It supports the JSON types used by the
-- public WordPress.com API: objects, arrays, strings, numbers, booleans/null.
local function decodeJSON(text)
    local pos = 1
    local len = #text

    local function skipWhitespace()
        while pos <= len do
            local c = text:sub(pos, pos)
            if c == " " or c == "\t" or c == "\r" or c == "\n" then
                pos = pos + 1
            else
                break
            end
        end
    end

    local function utf8char(code)
        if code <= 0x7F then
            return string.char(code)
        elseif code <= 0x7FF then
            return string.char(
                0xC0 + math.floor(code / 0x40),
                0x80 + (code % 0x40)
            )
        elseif code <= 0xFFFF then
            return string.char(
                0xE0 + math.floor(code / 0x1000),
                0x80 + (math.floor(code / 0x40) % 0x40),
                0x80 + (code % 0x40)
            )
        else
            return string.char(
                0xF0 + math.floor(code / 0x40000),
                0x80 + (math.floor(code / 0x1000) % 0x40),
                0x80 + (math.floor(code / 0x40) % 0x40),
                0x80 + (code % 0x40)
            )
        end
    end

    local parseValue

    local function parseString()
        pos = pos + 1 -- opening quote
        local out = {}

        while pos <= len do
            local c = text:sub(pos, pos)
            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif c == "\\" then
                pos = pos + 1
                local esc = text:sub(pos, pos)
                if esc == '"' or esc == "\\" or esc == "/" then
                    out[#out + 1] = esc
                    pos = pos + 1
                elseif esc == "b" then
                    out[#out + 1] = "\b"
                    pos = pos + 1
                elseif esc == "f" then
                    out[#out + 1] = "\f"
                    pos = pos + 1
                elseif esc == "n" then
                    out[#out + 1] = "\n"
                    pos = pos + 1
                elseif esc == "r" then
                    out[#out + 1] = "\r"
                    pos = pos + 1
                elseif esc == "t" then
                    out[#out + 1] = "\t"
                    pos = pos + 1
                elseif esc == "u" then
                    local hex = text:sub(pos + 1, pos + 4)
                    local code = tonumber(hex, 16)
                    if not code then error("Invalid JSON unicode escape") end
                    pos = pos + 5

                    -- Handle UTF-16 surrogate pairs if present.
                    if code >= 0xD800 and code <= 0xDBFF and text:sub(pos, pos + 1) == "\\u" then
                        local lowHex = text:sub(pos + 2, pos + 5)
                        local low = tonumber(lowHex, 16)
                        if low and low >= 0xDC00 and low <= 0xDFFF then
                            code = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
                            pos = pos + 6
                        end
                    end
                    out[#out + 1] = utf8char(code)
                else
                    error("Invalid JSON escape: " .. esc)
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end

        error("Unterminated JSON string")
    end

    local function parseNumber()
        local startPos = pos
        while pos <= len and text:sub(pos, pos):match("[%d%+%-%.eE]") do
            pos = pos + 1
        end
        local value = tonumber(text:sub(startPos, pos - 1))
        if value == nil then error("Invalid JSON number") end
        return value
    end

    local function parseArray()
        pos = pos + 1 -- [
        local result = {}
        skipWhitespace()

        if text:sub(pos, pos) == "]" then
            pos = pos + 1
            return result
        end

        while true do
            result[#result + 1] = parseValue()
            skipWhitespace()
            local c = text:sub(pos, pos)
            if c == "]" then
                pos = pos + 1
                return result
            elseif c ~= "," then
                error("Expected ',' or ']' in JSON array")
            end
            pos = pos + 1
            skipWhitespace()
        end
    end

    local function parseObject()
        pos = pos + 1 -- {
        local result = {}
        skipWhitespace()

        if text:sub(pos, pos) == "}" then
            pos = pos + 1
            return result
        end

        while true do
            if text:sub(pos, pos) ~= '"' then
                error("Expected JSON object key")
            end
            local key = parseString()
            skipWhitespace()
            if text:sub(pos, pos) ~= ":" then
                error("Expected ':' after JSON object key")
            end
            pos = pos + 1
            skipWhitespace()
            result[key] = parseValue()
            skipWhitespace()
            local c = text:sub(pos, pos)
            if c == "}" then
                pos = pos + 1
                return result
            elseif c ~= "," then
                error("Expected ',' or '}' in JSON object")
            end
            pos = pos + 1
            skipWhitespace()
        end
    end

    parseValue = function()
        skipWhitespace()
        local c = text:sub(pos, pos)
        if c == '"' then
            return parseString()
        elseif c == "{" then
            return parseObject()
        elseif c == "[" then
            return parseArray()
        elseif c == "-" or c:match("%d") then
            return parseNumber()
        elseif text:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif text:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif text:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end
        error("Unexpected JSON token at position " .. tostring(pos))
    end

    local value = parseValue()
    skipWhitespace()
    return value
end

local function htmlToText(value)
    if not value or value == "" then return "" end
    local doc = Document("<span>" .. value .. "</span>")
    local node = doc:selectFirst("span")
    if node then return node:text() end
    return value
end

local function releaseDate(date)
    if not date then return nil end
    return date:match("^(%d%d%d%d%-%d%d%-%d%d)")
end

local function apiURL(page)
    return apiBase
        .. "?number=" .. tostring(pageSize)
        .. "&page=" .. tostring(page)
        .. "&order=ASC"
        .. "&order_by=date"
        .. "&category=douluo-dalu-4"
        .. "&fields=ID,title,URL,date,slug,categories"
end

local function isDD4Post(post)
    -- Keep a local category check as well as the API filter. This prevents
    -- unrelated numbered posts from ever entering DD4 if WordPress ignores
    -- or changes its category query behaviour.
    for _, category in pairs(post.categories or {}) do
        if type(category) == "table" and category.slug == "douluo-dalu-4" then
            return true
        end
    end
    return false
end

local function chapterNumberFor(post, title)
    -- Most posts begin with the number, but Goldsilver's chapters 573, 874,
    -- and 908 use inconsistent titles. Their slugs still contain the number.
    return tonumber(title:match("^%s*(%d+)"))
        or tonumber(title:match("^%s*[Cc]hapter%s+(%d+)"))
        or tonumber((post.slug or ""):match("^(%d+)%-"))
end

local function normaliseChapterTitle(title, chapterNumber)
    title = title:gsub("^%s*[Cc]hapter%s+", "")
    if not title:match("^%s*" .. tostring(chapterNumber) .. "%f[^%d]") then
        return tostring(chapterNumber) .. " – " .. title
    end
    return title
end

local function fetchChapterData()
    local rawPosts = {}
    local page = 1

    -- WordPress.com allows up to 100 posts per request. Keep requesting pages
    -- until it returns fewer than 100. The safety cap is deliberately far
    -- above DD4's current chapter count while preventing an accidental loop.
    while page <= 50 do
        local doc = GETDocument(apiURL(page))
        local data = decodeJSON(doc:text())
        local posts = data and data.posts or {}

        for _, post in ipairs(posts) do
            rawPosts[#rawPosts + 1] = post
        end

        if #posts < pageSize then
            break
        end
        page = page + 1
    end

    local parsed = {}
    for _, post in ipairs(rawPosts) do
        local title = htmlToText(post.title or "")
        local chapterNumber = chapterNumberFor(post, title)
        if isDD4Post(post)
            and chapterNumber
            and chapterNumber >= firstGoldSilverChapter
            and post.URL then
            parsed[#parsed + 1] = {
                number = chapterNumber,
                title = normaliseChapterTitle(title, chapterNumber),
                link = shrinkURL(post.URL),
                release = releaseDate(post.date)
            }
        end
    end

    table.sort(parsed, function(a, b)
        if a.number == b.number then
            return a.title < b.title
        end
        return a.number < b.number
    end)

    local chapters = {}
    local seen = {}
    for _, chapter in ipairs(parsed) do
        if not seen[chapter.number] then
            local item = NovelChapter {
                order = chapter.number,
                title = chapter.title,
                link = chapter.link
            }
            if chapter.release then
                item:setRelease(chapter.release)
            end
            chapters[#chapters + 1] = item
            seen[chapter.number] = true
        end
    end

    return AsList(chapters)
end

local function normaliseChapterHTML(html)
    -- Some Goldsilver posts put the entire chapter in one paragraph and use
    -- pairs of <br> tags for paragraph breaks. Shosetsu may flatten those
    -- breaks, so turn them into real paragraph elements before rendering.
    return (html or ""):gsub("<br%s*/?>%s*<br%s*/?>", "</p><p>")
end

local function parsePassage(chapterURL)
    local cleanURL = (chapterURL or ""):gsub("[?#].*$", ""):gsub("/+$", "")
    local slug = cleanURL:match("/([^/]+)$")

    if not slug or slug == "" then
        error("Gold Silver Translation: could not identify the chapter URL")
    end

    -- The public page's theme markup changes depending on the client and was
    -- the cause of the old 'could not find chapter content' error. Fetch the
    -- post's rendered HTML directly from WordPress instead.
    local apiDoc = GETDocument(apiBase .. "slug:" .. slug .. "?fields=content")
    local data = decodeJSON(apiDoc:text())

    if not data or not data.content or data.content == "" then
        error("Gold Silver Translation: WordPress returned no chapter content")
    end

    local chapterHTML = normaliseChapterHTML(data.content)
    local doc = Document('<div id="shosetsu-passage">' .. chapterHTML .. "</div>")
    local content = doc:selectFirst("#shosetsu-passage")

    if not content then
        error("Gold Silver Translation: could not find chapter content")
    end

    return pageOfElem(content)
end

local function parseNovel(_, loadChapters)
    local info = NovelInfo {
        title = "Douluo Dalu 4: Ultimate Fighting",
        status = NovelStatus.PUBLISHING,
        description = "Gold Silver Translation's English fan translation of Douluo Dalu 4. Chapters are loaded directly from the site's public WordPress post feed rather than its outdated static chapter-list page."
    }

    if loadChapters then
        info:setChapters(fetchChapterData())
    end

    return info
end

local function listing()
    return {
        Novel {
            title = "Douluo Dalu 4: Ultimate Fighting",
            link = chapterListURL
        }
    }
end

return {
    id = id,
    name = "Gold Silver Translation",
    baseURL = baseURL,
    imageURL = "https://goldsilvertranslation.wordpress.com/favicon.ico",
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
-- {"id":94621783,"ver":"1.1.0","libVer":"1.0.0","author":"OpenAI","repo":"","dep":[]}

local id = 94621783
local baseURL = "https://goldsilvertranslation.wordpress.com"
local apiBase = "https://public-api.wordpress.com/rest/v1.1/sites/goldsilvertranslation.wordpress.com/posts/"
local chapterListURL = "/douluo-dalu-4/"
local pageSize = 100

-- Gold Silver Translation picked up DD4 from chapter 269.
local firstGoldSilverChapter = 269

local function shrinkURL(url)
    if not url then return "" end
    return url:gsub("^https?://goldsilvertranslation%.wordpress%.com", "")
end

local function expandURL(url)
    if not url then return baseURL end
    if url:match("^https?://") then return url end
    if url:sub(1, 1) ~= "/" then
        url = "/" .. url
    end
    return baseURL .. url
end

-- Small self-contained JSON decoder so this extension does not depend on a
-- second custom repository/library. It supports the JSON types used by the
-- public WordPress.com API: objects, arrays, strings, numbers, booleans/null.
local function decodeJSON(text)
    local pos = 1
    local len = #text

    local function skipWhitespace()
        while pos <= len do
            local c = text:sub(pos, pos)
            if c == " " or c == "\t" or c == "\r" or c == "\n" then
                pos = pos + 1
            else
                break
            end
        end
    end

    local function utf8char(code)
        if code <= 0x7F then
            return string.char(code)
        elseif code <= 0x7FF then
            return string.char(
                0xC0 + math.floor(code / 0x40),
                0x80 + (code % 0x40)
            )
        elseif code <= 0xFFFF then
            return string.char(
                0xE0 + math.floor(code / 0x1000),
                0x80 + (math.floor(code / 0x40) % 0x40),
                0x80 + (code % 0x40)
            )
        else
            return string.char(
                0xF0 + math.floor(code / 0x40000),
                0x80 + (math.floor(code / 0x1000) % 0x40),
                0x80 + (math.floor(code / 0x40) % 0x40),
                0x80 + (code % 0x40)
            )
        end
    end

    local parseValue

    local function parseString()
        pos = pos + 1 -- opening quote
        local out = {}

        while pos <= len do
            local c = text:sub(pos, pos)
            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif c == "\\" then
                pos = pos + 1
                local esc = text:sub(pos, pos)
                if esc == '"' or esc == "\\" or esc == "/" then
                    out[#out + 1] = esc
                    pos = pos + 1
                elseif esc == "b" then
                    out[#out + 1] = "\b"
                    pos = pos + 1
                elseif esc == "f" then
                    out[#out + 1] = "\f"
                    pos = pos + 1
                elseif esc == "n" then
                    out[#out + 1] = "\n"
                    pos = pos + 1
                elseif esc == "r" then
                    out[#out + 1] = "\r"
                    pos = pos + 1
                elseif esc == "t" then
                    out[#out + 1] = "\t"
                    pos = pos + 1
                elseif esc == "u" then
                    local hex = text:sub(pos + 1, pos + 4)
                    local code = tonumber(hex, 16)
                    if not code then error("Invalid JSON unicode escape") end
                    pos = pos + 5

                    -- Handle UTF-16 surrogate pairs if present.
                    if code >= 0xD800 and code <= 0xDBFF and text:sub(pos, pos + 1) == "\\u" then
                        local lowHex = text:sub(pos + 2, pos + 5)
                        local low = tonumber(lowHex, 16)
                        if low and low >= 0xDC00 and low <= 0xDFFF then
                            code = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
                            pos = pos + 6
                        end
                    end
                    out[#out + 1] = utf8char(code)
                else
                    error("Invalid JSON escape: " .. esc)
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end

        error("Unterminated JSON string")
    end

    local function parseNumber()
        local startPos = pos
        while pos <= len and text:sub(pos, pos):match("[%d%+%-%.eE]") do
            pos = pos + 1
        end
        local value = tonumber(text:sub(startPos, pos - 1))
        if value == nil then error("Invalid JSON number") end
        return value
    end

    local function parseArray()
        pos = pos + 1 -- [
        local result = {}
        skipWhitespace()

        if text:sub(pos, pos) == "]" then
            pos = pos + 1
            return result
        end

        while true do
            result[#result + 1] = parseValue()
            skipWhitespace()
            local c = text:sub(pos, pos)
            if c == "]" then
                pos = pos + 1
                return result
            elseif c ~= "," then
                error("Expected ',' or ']' in JSON array")
            end
            pos = pos + 1
            skipWhitespace()
        end
    end

    local function parseObject()
        pos = pos + 1 -- {
        local result = {}
        skipWhitespace()

        if text:sub(pos, pos) == "}" then
            pos = pos + 1
            return result
        end

        while true do
            if text:sub(pos, pos) ~= '"' then
                error("Expected JSON object key")
            end
            local key = parseString()
            skipWhitespace()
            if text:sub(pos, pos) ~= ":" then
                error("Expected ':' after JSON object key")
            end
            pos = pos + 1
            skipWhitespace()
            result[key] = parseValue()
            skipWhitespace()
            local c = text:sub(pos, pos)
            if c == "}" then
                pos = pos + 1
                return result
            elseif c ~= "," then
                error("Expected ',' or '}' in JSON object")
            end
            pos = pos + 1
            skipWhitespace()
        end
    end

    parseValue = function()
        skipWhitespace()
        local c = text:sub(pos, pos)
        if c == '"' then
            return parseString()
        elseif c == "{" then
            return parseObject()
        elseif c == "[" then
            return parseArray()
        elseif c == "-" or c:match("%d") then
            return parseNumber()
        elseif text:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif text:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif text:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end
        error("Unexpected JSON token at position " .. tostring(pos))
    end

    local value = parseValue()
    skipWhitespace()
    return value
end

local function htmlToText(value)
    if not value or value == "" then return "" end
    local doc = Document("<span>" .. value .. "</span>")
    local node = doc:selectFirst("span")
    if node then return node:text() end
    return value
end

local function releaseDate(date)
    if not date then return nil end
    return date:match("^(%d%d%d%d%-%d%d%-%d%d)")
end

local function apiURL(page)
    return apiBase
        .. "?number=" .. tostring(pageSize)
        .. "&page=" .. tostring(page)
        .. "&order=ASC"
        .. "&order_by=date"
        .. "&category=douluo-dalu-4"
        .. "&fields=ID,title,URL,date,slug"
end

local function chapterNumberFor(post, title)
    -- Most posts begin with the number, but Goldsilver's chapters 573, 874,
    -- and 908 use inconsistent titles. Their slugs still contain the number.
    return tonumber(title:match("^%s*(%d+)"))
        or tonumber(title:match("^%s*[Cc]hapter%s+(%d+)"))
        or tonumber((post.slug or ""):match("^(%d+)%-"))
end

local function normaliseChapterTitle(title, chapterNumber)
    title = title:gsub("^%s*[Cc]hapter%s+", "")
    if not title:match("^%s*" .. tostring(chapterNumber) .. "%f[^%d]") then
        return tostring(chapterNumber) .. " – " .. title
    end
    return title
end

local function fetchChapterData()
    local rawPosts = {}
    local page = 1

    -- WordPress.com allows up to 100 posts per request. Keep requesting pages
    -- until it returns fewer than 100. The safety cap is deliberately far
    -- above DD4's current chapter count while preventing an accidental loop.
    while page <= 50 do
        local doc = GETDocument(apiURL(page))
        local data = decodeJSON(doc:text())
        local posts = data and data.posts or {}

        for _, post in ipairs(posts) do
            rawPosts[#rawPosts + 1] = post
        end

        if #posts < pageSize then
            break
        end
        page = page + 1
    end

    local parsed = {}
    for _, post in ipairs(rawPosts) do
        local title = htmlToText(post.title or "")
        local chapterNumber = chapterNumberFor(post, title)
        if chapterNumber and chapterNumber >= firstGoldSilverChapter and post.URL then
            parsed[#parsed + 1] = {
                number = chapterNumber,
                title = normaliseChapterTitle(title, chapterNumber),
                link = shrinkURL(post.URL),
                release = releaseDate(post.date)
            }
        end
    end

    table.sort(parsed, function(a, b)
        if a.number == b.number then
            return a.title < b.title
        end
        return a.number < b.number
    end)

    local chapters = {}
    local seen = {}
    for _, chapter in ipairs(parsed) do
        if not seen[chapter.number] then
            local item = NovelChapter {
                order = chapter.number,
                title = chapter.title,
                link = chapter.link
            }
            if chapter.release then
                item:setRelease(chapter.release)
            end
            chapters[#chapters + 1] = item
            seen[chapter.number] = true
        end
    end

    return AsList(chapters)
end

local function parsePassage(chapterURL)
    local cleanURL = (chapterURL or ""):gsub("[?#].*$", ""):gsub("/+$", "")
    local slug = cleanURL:match("/([^/]+)$")

    if not slug or slug == "" then
        error("Gold Silver Translation: could not identify the chapter URL")
    end

    -- The public page's theme markup changes depending on the client and was
    -- the cause of the old 'could not find chapter content' error. Fetch the
    -- post's rendered HTML directly from WordPress instead.
    local apiDoc = GETDocument(apiBase .. "slug:" .. slug .. "?fields=content")
    local data = decodeJSON(apiDoc:text())

    if not data or not data.content or data.content == "" then
        error("Gold Silver Translation: WordPress returned no chapter content")
    end

    local doc = Document('<div id="shosetsu-passage">' .. data.content .. "</div>")
    local content = doc:selectFirst("#shosetsu-passage")

    if not content then
        error("Gold Silver Translation: could not find chapter content")
    end

    return pageOfElem(content)
end

local function parseNovel(_, loadChapters)
    local info = NovelInfo {
        title = "Douluo Dalu 4: Ultimate Fighting",
        status = NovelStatus.PUBLISHING,
        description = "Gold Silver Translation's English fan translation of Douluo Dalu 4. Chapters are loaded directly from the site's public WordPress post feed rather than its outdated static chapter-list page."
    }

    if loadChapters then
        info:setChapters(fetchChapterData())
    end

    return info
end

local function listing()
    return {
        Novel {
            title = "Douluo Dalu 4: Ultimate Fighting",
            link = chapterListURL
        }
    }
end

return {
    id = id,
    name = "Gold Silver Translation",
    baseURL = baseURL,
    imageURL = "https://goldsilvertranslation.wordpress.com/favicon.ico",
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
