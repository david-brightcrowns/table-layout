// Do not edit this file! Generated by Ragel.

package com.esotericsoftware.tablelayout;

import java.util.ArrayList;

class TableLayoutParser {
	static public void parse (BaseTableLayout table, String input) {
		Toolkit toolkit = table.toolkit;
		
		char[] data = (input + "  ").toCharArray();
		int cs, p = 0, pe = data.length, eof = pe, top = 0;
		int[] stack = new int[4];

		int s = 0;
		String name = null;
		String widgetLayoutString = null;
		String className = null;

		int columnDefaultCount = 0;
		ArrayList<String> values = new ArrayList(4);
		ArrayList<Object> parents = new ArrayList(8);
		Cell cell = null, rowDefaults = null, columnDefaults = null;
		Object parent = table, widget = null;
		RuntimeException parseRuntimeEx = null;
		boolean hasColon = false;

		boolean debug = false;
		if (debug) System.out.println();

		try {
%%{
machine tableLayout;

prepush {
	if (top == stack.length) {
		int[] newStack = new int[stack.length * 2];
		System.arraycopy(stack, 0, newStack, 0, stack.length);
		stack = newStack;
	}
}

action buffer { s = p; }
action name {
	name = new String(data, s, p - s);
	s = p;
}
action value {
	values.add(new String(data, s, p - s));
}
action tableProperty {
	if (debug) System.out.println("tableProperty: " + name + " = " + values);
	toolkit.setTableProperty((BaseTableLayout)parent, name, values);
	values.clear();
	name = null;
}
action cellDefaultProperty {
	if (debug) System.out.println("cellDefaultProperty: " + name + " = " + values);
	toolkit.setCellProperty(((BaseTableLayout)parent).defaults(), name, values);
	values.clear();
	name = null;
}
action startColumn {
	columnDefaults = ((BaseTableLayout)parent).columnDefaults(columnDefaultCount++);
}
action columnDefaultProperty {
	if (debug) System.out.println("columnDefaultProperty: " + name + " = " + values);
	toolkit.setCellProperty(columnDefaults, name, values);
	values.clear();
	name = null;
}
action startRow {
	if (debug) System.out.println("startRow");
	rowDefaults = ((BaseTableLayout)parent).row();
}
action rowDefaultValue {
	if (debug) System.out.println("rowDefaultValue: " + name + " = " + values);
	toolkit.setCellProperty(rowDefaults, name, values);
	values.clear();
	name = null;
}
action cellProperty {
	if (debug) System.out.println("cellProperty: " + name + " = " + values);
	toolkit.setCellProperty(cell, name, values);
	values.clear();
	name = null;
}
action widgetLayoutString {
	if (debug) System.out.println("widgetLayoutString: " + new String(data, s, p - s).trim());
	widgetLayoutString = new String(data, s, p - s).trim();
}
action newWidgetClassName {
	className = new String(data, s, p - s);
}
action newWidget {
	if (debug) System.out.println("newWidget, name:" + name + " class:" + className + " widget:" + widget);
	if (widget != null) { // 'label' or ['label'] or [name:'label']
		if (name != null && name.length() > 0) table.register(name, widget);
	} else if (className == null) {
		if (name.length() > 0) {
			if (hasColon) { // [name:]
				widget = toolkit.wrap(table, null);
				table.register(name, widget);
			} else { // [name]
				widget = table.getWidget(name);
				if (widget == null) {
					// Try the widget name as a class name.
					try {
						widget = toolkit.newWidget(table, name);
					} catch (RuntimeException ex) {
						throw new IllegalArgumentException("Widget not found with name: " + name);
					}
				}
			}
		} else // []
			widget = toolkit.wrap(table, null);
	} else { // [:class] and [name:class]
		widget = toolkit.newWidget(table, className);
		if (name.length() > 0) table.register(name, widget);
	}
	name = null;
	className = null;
}
action newLabel {
	if (debug) System.out.println("newLabel: " + new String(data, s, p - s));
	widget = toolkit.wrap(table, new String(data, s, p - s));
}
action startTable {
	if (debug) System.out.println("startTable, name:" + name);
	parents.add(parent);
	BaseTableLayout parentTable = null;
	for (int i = parents.size() - 1; i >= 0; i--) {
		Object object = parents.get(i);
		if (object instanceof BaseTableLayout) {
			parentTable = (BaseTableLayout)object;
			break;
		}
	}
	if (parentTable == null) parentTable = table;
	parent = toolkit.getLayout(toolkit.newTable(parentTable.getTable()));
	((BaseTableLayout)parent).setParent(parentTable);
	if (name != null) { // [name:{}]
		table.register(name, ((BaseTableLayout)parent).getTable());
		name = null;
	}
	cell = null;
	widget = null;
	fcall table;
}
action endTable {
	widget = parent;
	if (!parents.isEmpty()) {
		if (debug) System.out.println("endTable");
		parent = parents.remove(parents.size() - 1);
		fret;
	}
}
action startStack {
	if (debug) System.out.println("startStack, name:" + name);
	parents.add(parent);
	parent = toolkit.newStack();
	if (name != null) { // [name:<>]
		table.register(name, parent);
		name = null;
	}
	cell = null;
	widget = null;
	fcall stack;
}
action endStack {
	if (debug) System.out.println("endStack");
	widget = parent;
	parent = parents.remove(parents.size() - 1);
	fret;
}
action startWidgetSection {
	if (debug) System.out.println("startWidgetSection");
	parents.add(parent);
	parent = widget;
	widget = null;
	fcall widgetSection;
}
action endWidgetSection {
	if (debug) System.out.println("endWidgetSection");
	widget = parent;
	parent = parents.remove(parents.size() - 1);
	fret;
}
action addCell {
	if (debug) System.out.println("addCell");
	cell = ((BaseTableLayout)parent).add(toolkit.wrap(table, widget));
}
action addWidget {
	if (debug) System.out.println("addWidget");
	toolkit.addChild(parent, toolkit.wrap(table, widget), widgetLayoutString);
	widgetLayoutString = null;
}
action widgetProperty {
	if (debug) System.out.println("widgetProperty: " + name + " = " + values);
	Object propertyTarget = parent;
	if (parent instanceof BaseTableLayout)
		propertyTarget = ((BaseTableLayout)parent).getTable();
	toolkit.setProperty(table, propertyTarget, name, values);
	values.clear();
	name = null;
}

propertyValue =
	((alnum | '-' | '.' | '_' | '%')+) >buffer %value |
	('\'' ^'\''* >buffer %value '\'');
property = alnum+ >buffer %name (space* ':' space* propertyValue (',' propertyValue)* )?;

startTable = '{' @startTable;
startStack = '<' @startStack;
label = '\'' ^'\''* >buffer %newLabel '\'';
widget =
	# Widget name.
	'[' @{ widget = null; hasColon = false; } space* ^[\]:]* >buffer %name <:
	space* ':'? @{ hasColon = true; } space*
	(
		# Widget.
		label | startTable | startStack |
		# Class name.
		(^[\]':{]+ >buffer %newWidgetClassName)
	)?
	space* ']' @newWidget;

startWidgetSection = '(' @startWidgetSection;
widgetSection := space*
	# Widget properties.
	(property %widgetProperty (space+ property %widgetProperty)* space*)?
	(
		(
			# Child widget.
			(widget | label | startTable | startStack) space*
			# Contents layout string.
			(space* <: (alnum | ' ')+ >buffer %widgetLayoutString )?
		) %addWidget <:
		# Widget section.
		startWidgetSection? space*
	)* <:
	space* ')' @endWidgetSection;

stack := space* (
		# Child widget.
		(widget | label | startTable | startStack) %addWidget space*
		# Widget section.
		startWidgetSection? space*
	)* '>' @endStack;

table = space*
	# Table properties.
	(property %tableProperty (space+ property %tableProperty)* space*)?
	# Default cell properties.
	('*' space* property %cellDefaultProperty (space+ property %cellDefaultProperty)* space*)?
	# Default column properties.
	('|' %startColumn space* (property %columnDefaultProperty (space+ property %columnDefaultProperty)* space*)? '|'? space*)*
	(
		# Start row and default row properties.
		('---' %startRow space* (property %rowDefaultValue (space+ property %rowDefaultValue)* )? )? :>
		(
			# Cell widget.
			space* (widget | label | startTable | startStack) %addCell space*
			# Cell properties.
			(property %cellProperty (space+ property %cellProperty)* space*)?
			# Widget section.
			startWidgetSection? space*
		)
	)*
	space* '}' @endTable;

main := 
	space* '{'? <: table space* startWidgetSection? space*
;

write init;
write exec;
}%%
		} catch (RuntimeException ex) {
			parseRuntimeEx = ex;
		}

		if (p < pe) {
			int lineNumber = 1;
			int lineStartOffset = 0;
			for (int i = 0; i < p; i++) {
				if (data[i] == '\n') {
					lineNumber++;
					lineStartOffset = i;
				}
			}
			ParseException ex = new ParseException("Error parsing layout on line " + lineNumber + ":" + (p - lineStartOffset)
				+ " near: " + new String(data, p, Math.min(64, pe - p)), parseRuntimeEx);
			ex.line = lineNumber;
			ex.column = p - lineStartOffset;
			throw ex;
		} else if (top > 0)
			throw new ParseException("Error parsing layout (possibly an unmatched brace or quote): "
				+ new String(data, 0, Math.min(64, pe)), parseRuntimeEx);
	}

	%% write data;
}
