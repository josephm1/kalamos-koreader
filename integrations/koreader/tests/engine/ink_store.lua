-- Real KOReader LuaJIT/RapidJSON/filesystem; fixture root is a fresh Python TemporaryDirectory.
local plugin_root, fixture_root = assert(arg[1]), assert(arg[2])
require('setupkoenv')
package.path = plugin_root .. '/?.lua;' .. package.path
local json = require('rapidjson')
local store = require('inkstore')
store.root = fixture_root
local id = 'book-fixture'
local path = store.directory(id) .. '/ink-annotations.json'
local function read()
    local file = assert(io.open(path, 'rb'))
    local raw = assert(file:read('*a')); assert(file:close())
    return raw
end
local function replace(raw)
    local file = assert(io.open(path, 'wb'))
    assert(file:write(raw)); assert(file:close())
end
local fresh, err = store.annotations(id)
assert(fresh and #fresh.entries == 0, err)
assert(store.appendInk(id, {id = 'original', kind = 'full-page', anchor = {page = 0},
    strokes = json.array({{points = json.array({json.array({1, 2, 0.5, 0})})}})}))
local saved = read()
assert(store.annotations(id).entries[1].id == 'original')
local cases = {
    '{truncated', 'null', 'true', '[]', '{}',
    '{"entries":"damaged"}',
    '{"schema":"kalamos.ink-annotations/v99","entries":[]}',
    '{"bookId":"another-book","entries":[]}',
}
for _, raw in ipairs(cases) do
    replace(raw)
    local document, load_err = store.annotations(id)
    assert(not document and load_err, 'invalid sidecar must fail: ' .. raw)
    assert(not store.appendInk(id, {id = 'must-not-save'}))
    assert(not store.writeAnnotations(id, {entries = {}}))
    assert(read() == raw, 'original invalid bytes must stay intact')
    replace(saved)
    assert(store.annotations(id).entries[1].id == 'original')
end
assert(store.appendInk(id, {id = 'restored', kind = 'sticky', anchor = {stickyId = 'note'},
    strokes = json.array({})}))
local final = assert(store.annotations(id))
assert(#final.entries == 2 and final.entries[1].id == 'original' and final.entries[2].id == 'restored')
print('Passed 10 actual KOReader saved-ink scenarios (new, 8 invalid/restored, append after restore)')
