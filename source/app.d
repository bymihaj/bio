import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.getopt;

void main(string[] args)
{

	auto helpInformation = getopt(args, "device", (string option, string value) {	
		string content = cast(string)std.file.read(value);
		DeviceOption[] res = xmlToDevice(content);
		foreach ( device; res ) {
			writeln(device);
		}
	});
	
	/*
	writeln("Start");
	
	string content = cast(string)std.file.read("example//example1.xml");
	
	DeviceOption[] res = xmlToDevice(content);
	
	foreach ( device; res ) {
		writeln(device);
	}
	
	writeln("Finish");
	*/
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
