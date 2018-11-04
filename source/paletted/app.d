module paletted.app;

import std.stdio;
import std.algorithm;
import std.math;
import std.conv;
import std.range;
import std.string;
import std.utf;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;
import derelict.sdl2.net;

public struct Event {
	int type;
	void delegate(SDL_Event) callfunc;
}

public class App {
	SDL_Window* window;
	SDL_Renderer* renderer;
	Event[string] events;
	SDL_Surface*[string] surfaces;
	TTF_Font*[string] fonts;
	SDL_Texture*[string] textures;
	void delegate() onUpdate;
	Palette palette;
	bool running = true;
	int width = 300;
	int height = 300;
	int FPS = 60;
	int SPF = 1000 / 60;
	int frame = 0;
	Uint32 currentTick;
	
	
	this(int width = 300, int height = 300) {
		DerelictSDL2.load();
		DerelictSDL2ttf.load();
		SDL_Init(SDL_INIT_VIDEO);
		SDL_CreateWindowAndRenderer(width, height, SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED, &window, &renderer);
		this.palette = new Palette(this);
		TTF_Init();
	}
	void addEvent(Event e, string name) {
		this.events[name] = e;
	}
	void removeEvent(string name) {
		this.events[name] = Event(-1, null);
	}
	string addFont(string path, int size, string label) {
		writeln(path);
		auto str = label ~  "_" ~ size.to!string;
		if(!(str in fonts))
			fonts[str] = TTF_OpenFont(path.toUTFz!(char *), size);
		return str;
	}
	TTF_Font* getFont(string label) {
		return fonts[label];
	}
	string renderString(TTF_Font* font, string str) {
		SDL_Surface* surface = TTF_RenderUTF8_Blended(font, str.toUTFz!(char *), palette.currentColor);
		auto label = TTF_FontFaceFamilyName(font).to!string ~ "_" ~ str;
		surfaces[label] = surface;
		textures[label] = SDL_CreateTextureFromSurface(renderer, surface);
		return label;
	}
	SDL_Surface* getSurface(string label) {
		return surfaces[label];
	}
	SDL_Texture* getTexture(string label) {
		return textures[label];
	}
	void setFPS(int FPS) {
		this.FPS = FPS;
		this.SPF = 1000 / FPS;
	}
	
	int exec() {
		while(running) {
			currentTick = SDL_GetTicks();
			SDL_Event e;
			while(SDL_PollEvent(&e)) {
				this.events.values.filter!(i => i.type == e.type).each!(i => i.callfunc(e));
				if(e.type == SDL_QUIT) {
					running = false;
				}
			}
			onUpdate();
			SDL_RenderPresent(renderer);
			auto nowTick = SDL_GetTicks();
			if(nowTick - currentTick < SPF) {
				SDL_Delay(SPF - (nowTick - currentTick));
			}
			frame++;
		}
		onInterrupt();
		return 0;
	}
	void onInterrupt() {
		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(window);
		surfaces.values.writeln;
		textures.values.each!(i => SDL_DestroyTexture(i));
		fonts.values.each!(i => TTF_CloseFont(i));
		TTF_Quit();
		SDL_Quit();
	}
}

public class Palette {
	App app;
	this(App app) {
		this.app = app;
	}
	int color(Uint8 r, Uint8 g, Uint8 b, Uint8 a = 255) {
		return SDL_SetRenderDrawColor(app.renderer, r, g, b, a);
	}
	int color(SDL_Color color) {
		return SDL_SetRenderDrawColor(app.renderer, color.r, color.g, color.b, color.a);
	}
	SDL_Color currentColor() {
		SDL_Color color;
		SDL_GetRenderDrawColor(app.renderer, &color.r, &color.g, &color.b, &color.a);
		return color;
	}
	int currentColor(SDL_Color* color) {
		return SDL_GetRenderDrawColor(app.renderer, &color.r, &color.g, &color.b, &color.a);
	}
	int background(Uint8 r, Uint8 g, Uint8 b, Uint8 a = 255) {
		SDL_SetRenderDrawColor(app.renderer, r, g, b, a);
		return SDL_RenderClear(app.renderer);
	}
	int point(int x, int y) {
		return SDL_RenderDrawPoint(app.renderer, x, y);
	}
	int point(SDL_Point point) {
		return SDL_RenderDrawPoint(app.renderer, point.x, point.y);
	}
	int points(SDL_Point[] points) {
		return SDL_RenderDrawPoints(app.renderer, cast(const(SDL_Point)*)points, points.length.to!int);
	}
	int line(int x1, int y1, int x2, int y2) {
		return SDL_RenderDrawLine(app.renderer, x1, y1, x2, y2);
	}
	int lines(SDL_Point[] points) {
		return SDL_RenderDrawLines(app.renderer, cast(const(SDL_Point)*)points, points.length.to!int);
	}
	int rect(int x, int y, int w, int h) {
		SDL_Rect rect = SDL_Rect(x, y, w, h);
		return SDL_RenderDrawRect(app.renderer, &rect);
	}
	int rect(SDL_Rect rect) {
		return SDL_RenderDrawRect(app.renderer, &rect);
	}
	int rects(SDL_Rect[] rects) {
		return SDL_RenderDrawRects(app.renderer, cast(const(SDL_Rect)*)rects, rects.length.to!int);
	}
	int fill(int x, int y, int w, int h) {
		SDL_Rect rect = SDL_Rect(x, y, w, h);
		return SDL_RenderFillRect(app.renderer, &rect);
	}
	int fill(SDL_Rect rect) {
		return SDL_RenderFillRect(app.renderer, &rect);
	}
	int fills(SDL_Rect[] rects) {
		return SDL_RenderFillRects(app.renderer, cast(const(SDL_Rect)*)rects, rects.length.to!int);
	}
	int drawTexture(SDL_Texture* texture, int x, int y) {
		int iw, ih;
		SDL_QueryTexture(texture, null, null, &iw, &ih);
		auto txtRect = SDL_Rect(0, 0, iw, ih);
		auto pasteRect = SDL_Rect(x, y, iw, ih);
		return SDL_RenderCopy(app.renderer, texture, &txtRect, &pasteRect);
	}
	int drawString(string str, TTF_Font* font, int x, int y) {
		SDL_Surface* surface = TTF_RenderUTF8_Blended(font, str.toUTFz!(char *), currentColor);
		SDL_Texture* texture = SDL_CreateTextureFromSurface(app.renderer, surface);
		return drawTexture(texture, x, y);
	}
}
