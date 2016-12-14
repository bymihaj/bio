import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.getopt;
import std.conv;
import dgpio;
import core.thread;


void main(string[] args)
{

	string filePath  = "rul.xml";
	string inUse = "";
	getopt(args,
		"file|f", &filePath,
		"name|n", &inUse);
		
	NotRelay[] stuff;
	foreach ( device; getDeviceFromXml(filePath) ) {
		stuff ~= new NotRelay(device);
	}
	
	if (args.length > 1) {
		switch(args[1]) {
			case "device":
				deviceListCommand(stuff);	
				break;
			case "table":
				deviceTableCommand(stuff);	
				break;
			case "test":
				testDevice(stuff, inUse);
				break;
			default:
				writeln("Unsupported command: " ~ args[1]);
		}
	} else {
		writeln("Please select from commands: device, table, test");
	}
}

void deviceListCommand(NotRelay[] stuff) {
	foreach ( item; stuff ) {
		writeln(item.device.name);
	}
}

void deviceTableCommand(NotRelay[] stuff) {
	string marking = "%-12s | %-3s | %-12s | %-5s";
	writefln(marking, "Name", "Pin", "Type", "State");
	writefln(marking, "------------", "---", "------------", "------");
	foreach ( item; stuff ) {
		with( item ) {
			writefln(marking,device.name, device.pin.value, device.type.value, state());
		}
	}
}

void testDevice(NotRelay[] stuff, string deviceName) {
	foreach ( item; stuff ) {
		if ( item.device.name == deviceName ) {
			item.test();
			return;
		}
	}
	writefln("Device not found: %s", deviceName);
}

DeviceOption[] getDeviceFromXml(string path) {
	string content = cast(string)std.file.read(path);
	return xmlToDevice(content);
}

DeviceOption[] xmlToDevice(string content) {
	DeviceOption[] array ;
	DocumentParser parser = new DocumentParser(content);
	parser.onStartTag[DeviceOption.getItemDefinition()] = (ElementParser elementXml) {
		DeviceOption dev;
		dev.init(elementXml);
		elementXml.parse();
		array ~= dev;
	};
	parser.parse();
	return array;
}

unittest {
	DeviceOption[] devices = xmlToDevice(cast(string)std.file.read("example//example1.xml"));
	assert(devices.length == 2);
}

struct ElementDef {
	string value;
	string definition;
	
	this(string definition) {
		this.definition = definition;
	}
	
	void init(ElementParser elementParser) {
		elementParser.onEndTag[definition] = (in Element e) { value = e.text(); };
	}
	
	unittest {
		ElementDef elementDef = ElementDef("value");
		string content = "<?xml version="~"1.0?"~"><body><item><value>check</value></item></body>";
		DocumentParser parser = new DocumentParser(content);
		parser.onStartTag["item"] = (ElementParser elementXml) {
			elementDef.init(elementXml);
			elementXml.parse();
		};
		parser.parse();
		assert(elementDef.value == "check");
	}
}

struct DeviceOption {
	string name;
	ElementDef type = ElementDef("type");
	ElementDef pin = ElementDef("pin");
	
	void init(ElementParser elementParser) {
		name = elementParser.tag.attr[getNameAttrDef()];
		type.init(elementParser);
		pin.init(elementParser);
	}
	
	unittest {
		DeviceOption device;
		string content = "<?xml version="~"1.0?"~"><hardware> <device name=\"IoT\"><type>demo</type><pin>10</pin></device> </hardware>";
		DocumentParser parser = new DocumentParser(content);
		parser.onStartTag[getItemDefinition()] = (ElementParser elementXml) {
			device.init(elementXml);
			elementXml.parse();
		};
		parser.parse();
		assert(device.name == "IoT");
		assert(device.type.value == "demo");
		assert(device.pin.value == "10");
		
	}
	
	static string getItemDefinition() {
		return "device";
	}
	
	static string getNameAttrDef() {
		return "name";
	}
	
}

class NotRelay {
	DeviceOption device;
	GPIO gpio;
	
	this(DeviceOption device) {
		this.device = device;
		new GPIO(to!byte(device.pin.value));
	}
	
	string state() {
		if ( gpio.isInput() ) {
			return "OFF";
		} else if (gpio.isHigh()) {
			return "OFF";
		} else {
			return "ON";
		}
	}
	
	// TODO add interface log
	void on() {
		writefln("%s switched ON throw pin %s", device.name, gpio.gpio);
		gpio.setOutput();
		gpio.setLow();
	}
	
	// TODO add interface log
	void off() {
		writefln("%s switched OFF throw pin %s", device.name, gpio.gpio);
		gpio.setInput();
	}
	
	void test() {
		on();
		Thread.sleep( dur!("seconds")( 3 ) );
		off();
	}
}
