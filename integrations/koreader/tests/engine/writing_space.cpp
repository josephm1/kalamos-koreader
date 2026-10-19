// Executes the production extension against real CREngine, using a tiny Lua-result capture seam.
#include "lvdocview.h"
#include "lvfntman.h"
#include <cassert>
#include <map>
#include <string>
#include <vector>
#include <fstream>
#include <iostream>
#include <filesystem>
struct CreDocument { LVDocView *text_view; ldomDocument *dom_doc; };
struct lua_State {
    CreDocument *doc; std::string anchor;
    std::vector<std::string> stack; std::map<std::string, std::string> result;
};
void *luaL_checkudata(lua_State *L, int, const char*) { return L->doc; }
const char *luaL_checkstring(lua_State *L, int) { return L->anchor.c_str(); }
void lua_newtable(lua_State *L) { L->result.clear(); L->stack.clear(); }
void lua_pushstring(lua_State *L, const char *value) { L->stack.push_back(value); }
void lua_pushinteger(lua_State *L, int value) { L->stack.push_back(std::to_string(value)); }
void lua_pushboolean(lua_State *L, bool value) { L->stack.push_back(value ? "true" : "false"); }
void lua_rawset(lua_State *L, int) {
    auto value = L->stack.back(); L->stack.pop_back();
    auto key = L->stack.back(); L->stack.pop_back(); L->result[key] = value;
}
#include "../../engine/writingspace.inc"
static void paragraphs(ldomNode *node, std::vector<ldomNode*> &out) {
    if (node->isElement() && node->getNodeName() == "p") out.push_back(node);
    for (int i=0; i<node->getChildCount(); i++) paragraphs(node->getChildNode(i), out);
}
int main(int argc, char **argv) {
    assert(argc == 3);
    if (std::string(argv[1]).find(".html") != std::string::npos) {
    std::ofstream html(argv[1]);
    html << "<html><body><p>First paragraph stays in place.</p><p>Second paragraph gets writing space.</p><p>Third paragraph moves down.</p><table><tr><td><p>Table paragraph</p></td></tr></table><p dir='rtl'>RTL paragraph</p></body></html>";
    html.close();
    }
    InitFontManager(lString8()); assert(fontMan->RegisterFont(lString8(argv[2])));
    const bool epub = std::string(argv[1]).find(".epub") != std::string::npos;
    if (epub) {
        std::string cache = std::string(argv[1])+".cache/";
        std::filesystem::create_directories(cache);
        ldomDocCache::init(lString32(cache.c_str()), 32*1024*1024);
    }
    LVDocView view; view.setMinFileSizeToCache(0); view.Resize(600,800); view.setViewMode(DVM_SCROLL); view.setFontSize(24);
    const lString8 base("p { margin: 0; padding: 0; } body { margin: 0; padding: 0; }");
    view.setStyleSheet(base); assert(view.LoadDocument(argv[1])); view.Render();
    CreDocument document{&view, view.getDocument()};
    std::vector<ldomNode*> p; paragraphs(document.dom_doc->getRootNode(),p); assert(p.size() == 5);
    lvRect first, second, third;
    p[0]->getAbsRect(first);p[1]->getAbsRect(second);p[2]->getAbsRect(third);
    lua_State lua{&document, UnicodeToUtf8(ldomXPointer(p[1],0).toStringV2()).c_str(), {}, {}};
    assert(getWritingSpaceInfo(&lua) == 1);
    std::string anchor=lua.result["anchor"], selector=lua.result["selector"];
    if (epub) {
        view.swapToCache();
        assert(document.dom_doc->canBePartiallyRerendered());
        assert(document.dom_doc->enablePartialRerendering(true));
        view.setStyleSheet(base + lString8((selector+" { padding-bottom: 100px !important; }").c_str()));
        view.GetPos();
        assert(document.dom_doc->isRerenderingDelayed());
        LVGrayDrawBuf localPage(600,800,8);view.Draw(localPage,false);
        assert(document.dom_doc->getPartialRerenderingsCount()==1);
        lua.anchor=anchor;assert(getWritingSpaceInfo(&lua)==1);
        assert(std::stoi(lua.result["bottom"])-std::stoi(lua.result["top"])>=90);
        std::cout << "Fast canvas: visible chapter exposes final paper with only one fragment rerendered\n";
        document.dom_doc->enablePartialRerendering(false);
        view.setStyleSheet(base + lString8((selector+" { padding-bottom: 180px !important; }").c_str()));
        view.GetPos();
        assert(!document.dom_doc->isRerenderingDelayed());
        lvRect settled; p[1]->getAbsRect(settled);assert(settled.height()>=second.height()+170);
        assert(document.dom_doc->enablePartialRerendering(true));
        assert(!document.dom_doc->isRerenderingDelayed());
        document.dom_doc->enablePartialRerendering(false);
        view.setStyleSheet(base);view.GetPos();
        std::cout << "Cached multi-fragment EPUB: reproduced delayed canvas render; full-layout barrier settles geometry without delayed reload\n";
    }
    const auto originalHash=writingLayoutHash(&document);
    view.setStyleSheet(base + lString8((selector+" { padding-bottom: 120px !important; page-break-inside: avoid !important; }").c_str()));
    view.Render();
    lvRect afterFirst, afterSecond, afterThird;
    p[0]->getAbsRect(afterFirst);p[1]->getAbsRect(afterSecond);p[2]->getAbsRect(afterThird);
    assert(afterFirst.height() == first.height() && afterFirst.top == first.top);
    std::cerr << "selector=" << selector << " before=" << second.height() << " after=" << afterSecond.height() << "\n";
    assert(afterSecond.height() >= second.height()+110);
    assert(afterThird.top >= third.top+110);
    lua.anchor=anchor; assert(getWritingSpaceInfo(&lua)==1);
    assert(lua.result["anchor"]==anchor && lua.result["selector"]==selector);
    assert(std::stoi(lua.result["bottom"])-std::stoi(lua.result["top"]) >= 100);
    assert(writingLayoutHash(&document)!=originalHash);
    view.setStyleSheet(base);view.Render();
    assert(writingLayoutHash(&document)==originalHash);
    view.setStyleSheet(base + lString8((selector+" { padding-bottom: 120px !important; page-break-inside: avoid !important; }").c_str()));view.Render();
    view.setFontSize(32);view.Render();assert(getWritingSpaceInfo(&lua)==1);
    assert(writingLayoutHash(&document)!=originalHash);
    assert(lua.result["anchor"]==anchor && lua.result["selector"]==selector);
    view.setStyleSheet(base);view.Render();p[2]->getAbsRect(afterThird);
    view.setFontSize(24);view.Render();p[2]->getAbsRect(afterThird);assert(afterThird.top==third.top);
    // Font changes remain subject to the page-ink layout fence, even after restoring CSS.

    lua.anchor=UnicodeToUtf8(ldomXPointer(p[3],0).toStringV2()).c_str();assert(getWritingSpaceInfo(&lua)==0);
    lua.anchor=UnicodeToUtf8(ldomXPointer(p[4],0).toStringV2()).c_str();assert(getWritingSpaceInfo(&lua)==0);
    // Real page mode must move the following paragraph to another page, not just paint white.
    view.setViewMode(DVM_PAGES, 1);view.Resize(600,320);view.setStyleSheet(base);view.Render();
    int beforePage=view.getBookmarkPage(ldomXPointer(p[2],0));
    view.setStyleSheet(base + lString8((selector+" { padding-bottom: 220px !important; page-break-inside: avoid !important; }").c_str()));
    view.Render();assert(view.getBookmarkPage(ldomXPointer(p[2],0)) > beforePage);
    lua.anchor=anchor;assert(getWritingSpaceInfo(&lua)==1);assert(lua.result["anchor"]==anchor);
    // A multi-page paragraph exposes its paper at the tail, not at the source start.
    // Scroll mode provides deterministic full containment independent of page splitting.
    std::string longFile=std::string(argv[1])+".long.html";
    std::ofstream longHtml(longFile);
    longHtml << "<html><body><p>";
    for (int i = 0; i < 180; i++) longHtml << "A long paragraph with words and space. ";
    longHtml << "</p><p>Following paragraph.</p></body></html>";longHtml.close();
    view.setViewMode(DVM_SCROLL); view.Resize(600,800); view.setFontSize(25);
    view.setStyleSheet(lString8("body {margin:0;padding:0} p {margin:0;padding:0;padding-bottom:120px!important}"));
    assert(view.LoadDocument(longFile.c_str()));view.Render();
    document.dom_doc=view.getDocument();p.clear();paragraphs(document.dom_doc->getRootNode(),p);
    lua.anchor=UnicodeToUtf8(ldomXPointer(p[0],0).toStringV2()).c_str();
    view.goToBookmark(document.dom_doc->createXPointer(lString32(lua.anchor.c_str())));
    assert(getWritingSpaceInfo(&lua)==1);
    assert(std::stoi(lua.result["top"]) > 800);
    std::string tail=lua.result["tail"];
    auto tailPointer=document.dom_doc->createXPointer(lString32(tail.c_str()));
    view.goToBookmark(tailPointer);view.SetPos(tailPointer.toPoint().y); // Same as production gotoXPointer.
    assert(getWritingSpaceInfo(&lua)==1);
    std::cerr << "tail reveal top=" << lua.result["top"] << " bottom=" << lua.result["bottom"] << "\n";
    assert(std::stoi(lua.result["top"]) >= 0 && std::stoi(lua.result["bottom"]) <= 800);
    view.setViewMode(DVM_PAGES,1);view.Render();
    tailPointer=document.dom_doc->createXPointer(lString32(tail.c_str()));
    view.goToPage(view.getBookmarkPage(tailPointer));
    assert(getWritingSpaceInfo(&lua)==1);
    std::cerr << "page tail reveal visible=" << lua.result["visible"] << " top=" << lua.result["top"] << " bottom=" << lua.result["bottom"] << "\n";
    assert(lua.result["visible"]=="true");
    std::string headingFile=std::string(argv[1])+".heading.html";
    std::ofstream headings(headingFile);headings << "<html><body><h2>Legalism</h2><p>Following text moves down.</p></body></html>";headings.close();
    view.setViewMode(DVM_SCROLL);view.setStyleSheet(lString8("body,h2,p {margin:0;padding:0}"));
    assert(view.LoadDocument(headingFile.c_str()));view.Render();document.dom_doc=view.getDocument();
    auto headingPointer=document.dom_doc->createXPointer(lString32("/html/body/h2/text().0"));
    assert(!headingPointer.isNull());lua.anchor=UnicodeToUtf8(headingPointer.toStringV2()).c_str();
    assert(getWritingSpaceInfo(&lua)==1);
    auto headingSelector=lua.result["selector"];
    view.setStyleSheet(lString8((headingSelector+" {padding-bottom:100px!important}").c_str()));view.Render();
    assert(getWritingSpaceInfo(&lua)==1);int small=std::stoi(lua.result["bottom"])-std::stoi(lua.result["top"]);
    view.setStyleSheet(lString8((headingSelector+" {padding-bottom:200px!important}").c_str()));view.Render();
    assert(getWritingSpaceInfo(&lua)==1);assert(std::stoi(lua.result["bottom"])-std::stoi(lua.result["top"])>=small+90);
    std::cout << "Actual CREngine: exact paragraph CSS, downstream reflow, stable anchors, font change, rollback and unsupported block checks passed\n";
    return 0;
}
