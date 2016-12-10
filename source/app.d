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
	if (args.length > 1) {
		switch(args[1]) {
			
			case "device":
				deviceListCommand(filePath);	
				break;
			case "table":
				deviceTableCommand(filePath);	
				break;
			case "test":
				testDevice(filePath, inUse);
				break;
			default:
				writeln("Unsupported command: " ~ args[1]);
		}
	} else {
		writeln("Please select from commands: device, table, test");
	}
}

void deviceListCommand(string value) {
	foreach ( device; getDeviceFromXml(value) ) {
		writeln(device.name);
	}
}

void deviceTableCommand(string value) {
	string marking = "%-12s | %-3s | %-12s";
	writefln(marking, "Name", "Pin", "Type");
	writefln(marking, "------------", "---", "------------");
	foreach ( device; getDeviceFromXml(value) ) {
		writefln(marking,device.name, device.pin.value, device.type.value);
	}
}

void testDevice(string filePath, string deviceName) {
	foreach ( device; getDeviceFromXml(filePath) ) {
		if ( device.name == deviceName ) {
			writeln("Yes, I found");
			GPIO gpio = new GPIO(to!byte(device.pin.value));
			gpio.setOutput();
			gpio.setHigh();
			Thread.sleep( dur!("seconds")( 3 ) );
			writeln("Before sleeping");
			gpio.setLow();
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
