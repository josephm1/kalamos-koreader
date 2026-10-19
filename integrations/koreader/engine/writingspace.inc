// Annotation-only paragraph padding. No DOM nodes/attributes or original EPUB files are mutated.
// Return an exact CSS selector from the engine's real DOM, never from a guessed XPointer parser.
static int getWritingSpaceInfo(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *xp = luaL_checkstring(L, 2);
    ldomXPointer pointer = doc->dom_doc->createXPointer(lString32(xp));
    if (pointer.isNull()) return 0;
    ldomNode *node = pointer.getNode();
    while (node && !node->isNull()) {
        if (node->isElement() && node->getRendMethod() == erm_final) {
            lString32 name = node->getNodeName();
            if (name == "p" || name == "h1" || name == "h2" || name == "h3" ||
                name == "h4" || name == "h5" || name == "h6" || name == "blockquote" || name == "div") break;
        }
        node = node->getParentNode();
    }
    if (!node || node->isNull() || node->getRendMethod() != erm_final) return 0;
    lString8 selector;
    for (ldomNode *part = node; part && !part->isRoot(); part = part->getParentNode()) {
        if (!part->isElement() || part->isBoxingNode(true)) return 0;
        lUInt16 id = part->getNodeId();
        if (part->getNodeName() == "table" || part->getNodeName() == "td" ||
            part->getNodeName() == "th" || part->getNodeName() == "li" || part->getNodeName() == "aside")
            return 0;
        css_style_ref_t style = part->getStyle();
        if (part->getAttributeValue("dir") == "rtl" ||
            (!style.isNull() && (style->float_ != css_f_none || style->direction == css_dir_rtl)))
            return 0;
        lString8 name = UnicodeToUtf8(part->getNodeName());
        if (name.empty()) return 0;
        // Element names are controlled by the parsed document, not interpolated user CSS.
        for (int i = 0; i < name.length(); i++) {
            char c = name[i];
            if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                  (c >= '0' && c <= '9') || c == '_' || c == '-')) return 0;
        }
        int index = 1;
        ldomNode *parent = part->getParentNode();
        if (parent) for (int i = 0; i < part->getNodeIndex(); i++) {
            ldomNode *sibling = parent->getChildNode(i);
            if (sibling->isElement() && sibling->getNodeId() == id) index++;
        }
        lString8 step = name + ":nth-of-type(" + lString8().appendDecimal(index) + ")";
        selector = step + (selector.empty() ? lString8() : lString8(" > ") + selector);
        // CREngine intentionally stops CSS ancestry at DocFragment. Its synthetic outer body
        // cannot participate in a selector; the fragment sibling index still scopes the chapter.
        if (part->getNodeName() == "DocFragment") break;
    }
    ldomXPointerEx tail(node, 0);
    if (!tail.lastInnerTextNode()) return 0;
    tail.setOffset(tail.getNode()->getText().length());
    lvRect last, block;
    if (!tail.getRect(last)) return 0;
    node->getAbsRect(block);
    // The last line ends before our padding. Exclude line descent/border from writable paper.
    lvPoint start(block.left + 2, last.bottom + 3);
    lvPoint end(block.right - 2, block.bottom - 3);
    bool visible = start.y < end.y && doc->text_view->docToWindowPoint(start) &&
        doc->text_view->docToWindowPoint(end, true) && start.x < end.x && start.y < end.y;
    lua_newtable(L);
#define SPACE_STRING(key, value) lua_pushstring(L, key); lua_pushstring(L, (value).c_str()); lua_rawset(L, -3)
#define SPACE_INT(key, value) lua_pushstring(L, key); lua_pushinteger(L, value); lua_rawset(L, -3)
    SPACE_STRING("anchor", UnicodeToUtf8(ldomXPointer(node, 0).toStringV2()));
    SPACE_STRING("tail", UnicodeToUtf8(tail.toStringV2()));
    SPACE_STRING("selector", selector);
    SPACE_STRING("text", UnicodeToUtf8(node->getText(0, 240)));
    SPACE_INT("left", start.x); SPACE_INT("top", start.y);
    SPACE_INT("right", end.x); SPACE_INT("bottom", end.y);
    lua_pushstring(L, "visible"); lua_pushboolean(L, visible); lua_rawset(L, -3);
#undef SPACE_STRING
#undef SPACE_INT
    return 1;
}

// CREngine's cache hash includes its initial display-style sentinel. That sentinel
// changes after the first stylesheet edit even when identical geometry is restored.
// Page ink needs an equivalent-layout fingerprint, not a cache-generation identity.
static lUInt32 hashWritingLayoutNode(ldomNode *node, lUInt32 hash) {
    if (node->isElement()) {
        lvRect rect;node->getAbsRect(rect);
        hash=hash*31+(lUInt32)rect.left;hash=hash*31+(lUInt32)rect.top;
        hash=hash*31+(lUInt32)rect.right;hash=hash*31+(lUInt32)rect.bottom;
        css_style_ref_t style=node->getStyle();font_ref_t font=node->getFont();
        hash=hash*31+calcHash(style);hash=hash*31+calcHash(font);
    }
    for(int i=0;i<node->getChildCount();i++) hash=hashWritingLayoutNode(node->getChildNode(i),hash);
    return hash;
}
static lUInt32 writingLayoutHash(CreDocument *doc) {
    // Rendering is ensured before traversing. Lua caches this once per engine hash
    // and reader instance; the document-wide traversal is never per pen sample.
    doc->text_view->getPageCount();
    lUInt32 hash=hashWritingLayoutNode(doc->dom_doc->getRootNode(),2166136261u);
    hash=hash*31+(lUInt32)doc->text_view->GetWidth();
    hash=hash*31+(lUInt32)doc->text_view->GetHeight();
    hash=hash*31+(lUInt32)doc->text_view->GetFullHeight();
    return hash*31+(lUInt32)doc->text_view->getPageCount();
}
static int getWritingLayoutHash(lua_State *L) {
    CreDocument *doc=(CreDocument*)luaL_checkudata(L,1,"credocument");
    lua_pushinteger(L,writingLayoutHash(doc));return 1;
}
