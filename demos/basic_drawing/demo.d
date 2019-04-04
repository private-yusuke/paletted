import paletted;
import std.stdio;
import std.algorithm;
import std.conv;
import std.utf;
import std.range;
import std.math;

void main() {
	auto app = new App(600, 450);
	
	int time = 0;
	void fw(SDL_Event e) {
		switch(e.key.keysym.sym) {
			case SDLK_w:
				time++;
				break;
			case SDLK_s:
				time--;
				break;
			case SDLK_p:
				writefln("%s %f %f", time, cos(time / 180.0 * PI), sin(time / 180.0 * PI));
				break;
			default:
				break;
		}
	}
	const ubyte N = 20;
	SDL_Color[] colorarr;
	foreach(i; 0..N) {
		Uint8 k = ((255 / N) * i).to!Uint8;
		colorarr ~= SDL_Color(k, k, k, 255);
	}
	auto rectarr = N.iota.map!(i => SDL_Rect(50+i*10, 50+i*10, 30, 30)).array;
	auto pointarr = N.iota.map!(i => SDL_Point((sin(i * (PI / 180) * (360 / N)) * 20 + 50).to!int, (cos(i * (PI / 180) * (360 / N)) * 20 + 50).to!int));
	auto font = app.addFont("/Library/Fonts/Arial.ttf", 30, "Arial");
	font.writeln;
	
	auto texture = app.renderString(app.getFont(font), "あhello");
	void update() {
		/*with(app.palette) {
			background(128, 0, 128);
			color(40, 40, 40);
			point(time/100, 20);
			line(100, 100, (100+cos(time / 10.)*30).to!int, (100+sin(time / 10.) * 30).to!int);
			color(20, 30, 40);
			rect(150, 150, 50, 50);
			rect(SDL_Rect(20, 30, 40, 50));
			rects(3.iota.map!(i => SDL_Rect(i*10, i*10, 30, 30)).array);
			points(100.iota.map!(i => SDL_Point(i, i/2)).array);
			foreach(i; 0..N) {
				color(colorarr[i]);
				fill(rectarr[i]);
			}
			SDL_Point[] rendpoints;
			foreach(i; 0..N) {
				rendpoints ~= SDL_Point(50, 50);
				rendpoints ~= pointarr[i];
			}
			lines(rendpoints);
			color(66, 134, 244);
			fill(60, 30, app.frame%150, 30);
			fill(30, 60, 30, (app.frame + 75)%150);
			drawTexture(app.getTexture(texture), 100+time, 200);
			drawString(app.frame.to!string, app.getFont(font), app.width - 100, 50);
		}
		*/
		with(app.palette) {
			background(100, 140, 80);
			foreach(i; 0..10) {
				ubyte v = (app.currentTick + i * 20) % 256;
				color(v, v, v);
				rect(10*i, 10, 10, 10);
			}
			color(20, 20, 20);
			drawString(app.currentTick.to!string, app.getFont(font), app.width - 100, 50);
		}
	}
	app.onUpdate = &update;
	app.addEvent(Event(SDL_KEYDOWN, &fw), "press_w");
	// app.removeEvent("q_quit");
	
	app.exec();
}

