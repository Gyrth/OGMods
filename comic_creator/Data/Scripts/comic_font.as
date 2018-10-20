class ComicFont : ComicElement{
	string font_name;
	int font_size;
	string font_color;
	bool shadowed;
	FontSetup font("edosz", 75, HexColor("#CCCCCC"), true);
	ComicFont(string _font_name, int _font_size, string _font_color, bool _shadowed){
		font_name = _font_name;
		font_size = _font_size;
		font_color = _font_color;
		shadowed = _shadowed;

		font.fontName = _font_name;
		font.size = _font_size;
		font.color = HexColor(_font_color);
		font.shadowed = _shadowed;
	}
	string GetSaveString(){
		return "set_font " + font_name + " " + font_size + " " + font_color + " " + (shadowed ? "true" : "false");
	}
}
