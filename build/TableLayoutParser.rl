// Do not edit this file! Generated from Ragel.

package com.esotericsoftware.tablelayout;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;

import com.esotericsoftware.tablelayout.BaseTableLayout.Cell;

class TableLayoutParser {
	static public void parse (BaseTableLayout table, Cell cell, String input) {
		char[] data = (input + "  ").toCharArray();
		int cs, p = 0, pe = data.length, eof = pe, top = 0;
		int[] stack = new int[4];

		int s = 0;
		String name = null;
		ArrayList<String> values = new ArrayList(4);
		ArrayList<Object> parents = new ArrayList(8);
		Cell rowDefaults = null, columnDefaults = null;
		Object parent = table, widget = null;
		String widgetLayoutString = null;

		if (cell != null) {
			// BOZO - Set cell state.
		}

		RuntimeException parseRuntimeEx = null;
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
				System.out.println("tableProperty: " + name + " = " + values);
				setTableProperty((BaseTableLayout)parent, name, values);
			}
			action cellDefaultProperty {
				System.out.println("cellDefaultProperty: " + name + " = " + values);
				setCellProperty(((BaseTableLayout)parent).getCellDefaults(), name, values);
			}
			action startColumn {
				int column = ((BaseTableLayout)parent).getColumnDefaults().size();
				columnDefaults = ((BaseTableLayout)parent).getColumnDefaults(column);
			}
			action columnDefaultProperty {
				System.out.println("columnDefaultProperty: " + name + " = " + values);
				setCellProperty(columnDefaults, name, values);
			}
			action startRow {
				System.out.println("startRow");
				rowDefaults = ((BaseTableLayout)parent).startRow();
			}
			action rowDefaultValue {
				System.out.println("rowDefaultValue: " + name + " = " + values);
				setCellProperty(rowDefaults, name, values);
			}
			action cellProperty {
				System.out.println("cellProperty: " + name + " = " + values);
				setCellProperty(cell, name, values);
			}
			action setTitle {
				System.out.println("setTitle: " + new String(data, s, p - s));
				if (widget instanceof BaseTableLayout)
					((BaseTableLayout)widget).setTitle(new String(data, s, p - s));
				else
					table.setTitle(widget, new String(data, s, p - s));
			}
			action widgetLayoutString {
				System.out.println("widgetLayoutString: " + new String(data, s, p - s));
				widgetLayoutString = new String(data, s, p - s);
			}
			action newWidget {
				String className = p > s ? new String(data, s, p - s) : null;
				System.out.println("newWidget: " + name + " " + className);
				widget = null;
				if (className == null) {
					if (!name.isEmpty()) {
						widget = table.getWidget(name);
						if (widget == null) {
							// Try the widget name as a class name.
							try {
								widget = table.wrap(newWidget(name));
							} catch (Exception ex) {
								throw new IllegalArgumentException("Widget not found with name: " + name);
							}
						}
					}
				} else {
					try {
						widget = table.wrap(newWidget(className));
					} catch (Exception ex) {
						throw new RuntimeException("Error creating instance of class: " + className, ex);
					}
					if (!name.isEmpty()) table.setName(name, widget);
				}
			}
			action newLabel {
				System.out.println("newLabel: " + new String(data, s, p - s));
				widget = table.newLabel(new String(data, s, p - s));
			}
			action startTable {
				System.out.println("startTable");
				parents.add(parent);
				parent = table.newTableLayout();
				cell = null;
				widget = null;
				fcall table;
			}
			action endTable {
				widget = parent;
				if (!parents.isEmpty()) {
					System.out.println("endTable");
					parent = parents.remove(parents.size() - 1);
					fret;
				}
			}
			action startWidgetSection {
				System.out.println("startWidgetSection");
				parents.add(parent);
				parent = widget;
				widget = null;
				fcall widgetSection;
			}
			action endWidgetSection {
				System.out.println("endWidgetSection");
				widget = parent;
				parent = parents.remove(parents.size() - 1);
				fret;
			}
			action addCell {
				System.out.println("addCell");
				cell = ((BaseTableLayout)parent).add(table.wrap(widget));
			}
			action addWidget {
				System.out.println("addWidget");
				table.addChild(parent, table.wrap(widget), widgetLayoutString);
			}
			action widgetProperty {
				System.out.println("widgetProperty: " + name + " = " + values);
				try {
					try {
						invokeMethod(parent, name, values);
					} catch (NoSuchMethodException ex1) {
						try {
							invokeMethod(parent, "set" + Character.toUpperCase(name.charAt(0)) + name.substring(1),
								values);
						} catch (NoSuchMethodException ex2) {
							try {
								Field field = parent.getClass().getField(name);
								Object value = convertType(parent, values.get(0), field.getType());
								if (value != null) field.set(parent, value);
							} catch (Exception ex3) {
								throw new RuntimeException("No method, bean property, or field found.");
							}
						}
					}
				} catch (RuntimeException ex) {
					throw new RuntimeException("Error setting property: " + name + "\nClass: " + parent.getClass()
						+ "\nValues: " + values, ex);
				}
				values.clear();
			}

			title = '<' ^'>'* >buffer %setTitle '>';
			propertyValue = (('-'? (alnum | '.' | '_')+ '%'?) >buffer %value | ('\'' ^'\''* >buffer %value '\''));
			property = alnum+ >buffer %name (space* ':' space* propertyValue (',' propertyValue)* )?;

			widget = '[' space* ^[\]:]* >buffer %name (space* ':' space* ^[\]]+ >buffer)? space* ']' @newWidget;
			label = '\'' ^'\''* >buffer %newLabel '\'';
			startTable = '{' @startTable;

			startWidgetSection = '(' @startWidgetSection;
			widgetSection := space*
				# Widget properties.
				(property %widgetProperty (space+ property %widgetProperty)* space*)?
				(
					(
						# Widget contents.
						(widget | label | startTable) space*
						# Contents title.
						(title space*)? <:
						# Contents layout string.
						(space* <: (alnum | ' ')+ >buffer %widgetLayoutString :> space*)?
					) %addWidget <:
					# Contents properties.
					startWidgetSection?
					space*
				)*
				space* ')' @endWidgetSection;

			table = space*
				# Table title.
				(title space*)? <:
				# Table properties.
				(property %tableProperty (space+ property %tableProperty)* space*)?
				# Default cell properties.
				('*' space* property %cellDefaultProperty (space+ property %cellDefaultProperty)* space*)?
				# Default column properties.
				('|' %startColumn space* (property %columnDefaultProperty (space+ property %columnDefaultProperty)* space*)? '|'? space*)*
				(
					# Start row and default row properties.
					('---' %startRow space* (property %rowDefaultValue (space+ property %rowDefaultValue)* )? )?
					(
						# Cell contents.
						space* (widget | label | startTable) %addCell space*
						# Contents title.
						(title space*)?
						# Cell properties.
						(property %cellProperty (space+ property %cellProperty)* space*)?
						# Contents properties.
						startWidgetSection? space*
					)+
				)+
				space* '}' %endTable;
			
			main := 
				space* ('{')? <: table (space* title)? <: space*
			;

			write init;
			write exec;
		}%%
		} catch (RuntimeException ex) {
			parseRuntimeEx = ex;
		}

		if (p < pe) {
			throw new IllegalArgumentException("Error parsing layout near: " + new String(data, p, pe - p), parseRuntimeEx);
		} else if (top > 0) 
			throw new IllegalArgumentException("Error parsing layout (possibly an unmatched brace or quote): " + input, parseRuntimeEx);
	}

	%% write data;

	static public void setTableProperty (BaseTableLayout table, String name, ArrayList<String> values) {
		name = name.toLowerCase();
		for (int i = 0, n = values.size(); i < n; i++)
			values.set(i, values.get(i).toLowerCase());
		try {
			String value;
			if (name.equals("size")) {
				switch (values.size()) {
				case 1:
					value = values.get(0);
					// BOZO - Fix table %.
					if (value.endsWith("%"))
						table.fillX = table.fillY = Integer.parseInt(value.substring(0, value.length() - 1)) / 100f;
					else
						table.width = table.height = Integer.parseInt(values.get(0));
					break;
				case 2:
					value = values.get(0);
					if (value.endsWith("%"))
						table.fillX = Integer.parseInt(value.substring(0, value.length() - 1)) / 100f;
					else
						table.width = Integer.parseInt(values.get(0));
					value = values.get(1);
					if (value.endsWith("%"))
						table.fillY = Integer.parseInt(value.substring(0, value.length() - 1)) / 100f;
					else
						table.height = Integer.parseInt(values.get(0));
					break;
				}

			} else if (name.equals("width")) {
				value = values.get(0);
				if (value.endsWith("%"))
					table.fillX = Integer.parseInt(value.substring(0, value.length() - 1)) / 100f;
				else
					table.width = Integer.parseInt(value);

			} else if (name.equals("height")) {
				value = values.get(0);
				if (value.endsWith("%"))
					table.fillY = Integer.parseInt(value.substring(0, value.length() - 1)) / 100f;
				else
					table.height = Integer.parseInt(value);

			} else if (name.equals("padding") || name.equals("pad")) {
				switch (values.size()) {
				case 4:
					value = values.get(3);
					if (value.length() > 0) table.padRight = Integer.parseInt(value);
				case 3:
					value = values.get(2);
					if (value.length() > 0) table.padBottom = Integer.parseInt(value);
				case 2:
					value = values.get(0);
					if (value.length() > 0) table.padTop = Integer.parseInt(value);
					value = values.get(1);
					if (value.length() > 0) table.padLeft = Integer.parseInt(value);
					break;
				case 1:
					table.padTop = table.padLeft = table.padBottom = table.padRight = Integer.parseInt(values.get(0));
					break;
				default:
					throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
				}

			} else if (name.startsWith("padding") || name.startsWith("pad")) {
				name = name.replace("padding", "").replace("pad", "");
				if (name.equals("top") || name.equals("t"))
					table.padTop = Integer.parseInt(values.get(0));
				else if (name.equals("left") || name.equals("l"))
					table.padLeft = Integer.parseInt(values.get(0));
				else if (name.equals("bottom") || name.equals("b"))
					table.padBottom = Integer.parseInt(values.get(0));
				else if (name.equals("right") || name.equals("r"))
					table.padRight = Integer.parseInt(values.get(0));
				else
					throw new IllegalArgumentException("Unknown property.");

			} else if (name.equals("align")) {
				table.align = 0;
				for (int i = 0, n = values.size(); i < n; i++) {
					value = values.get(i);
					if (value.equals("center"))
						table.align |= BaseTableLayout.CENTER;
					else if (value.equals("left"))
						table.align |= BaseTableLayout.LEFT;
					else if (value.equals("right"))
						table.align |= BaseTableLayout.RIGHT;
					else if (value.equals("top"))
						table.align |= BaseTableLayout.TOP;
					else if (value.equals("bottom"))
						table.align |= BaseTableLayout.BOTTOM;
					else
						throw new IllegalArgumentException("Invalid value: " + value);
				}

			} else if (name.equals("debug")) {
				if (values.size() == 0) table.debug = "all,";
				for (int i = 0, n = values.size(); i < n; i++)
					table.debug += values.get(i) + ",";

			} else
				throw new IllegalArgumentException("Unknown property: " + name);
		} catch (Exception ex) {
			throw new IllegalArgumentException("Error setting property: " + name, ex);
		}
		values.clear();
	}

	static public void setCellProperty (Cell c, String name, ArrayList<String> values) {
		name = name.toLowerCase();
		for (int i = 0, n = values.size(); i < n; i++)
			values.set(i, values.get(i).toLowerCase());
		try {
			String value;
			if (name.equals("expand")) {
				if (values.size() == 0) c.expandWidth = c.expandHeight = 1;
				for (int i = 0, n = values.size(); i < n; i++) {
					value = values.get(i);
					if (value.equals("x"))
						c.expandWidth = 1;
					else if (value.equals("y"))
						c.expandHeight = 1;
					else if (value.equals("false"))
						c.expandWidth = c.expandHeight = 0;
					else {
						switch (i) {
						case 0:
							c.expandWidth = Integer.parseInt(value);
							break;
						case 1:
							c.expandHeight = Integer.parseInt(value);
							break;
						default:
							throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
						}
					}
				}

			} else if (name.equals("fill")) {
				if (values.size() == 0) c.fillWidth = c.fillHeight = 1f;
				for (int i = 0, n = values.size(); i < n; i++) {
					value = values.get(i);
					if (value.equals("x"))
						c.fillWidth = 1f;
					else if (value.equals("y")) //
						c.fillHeight = 1f;
					else {
						switch (i) {
						case 0:
							c.fillWidth = Integer.parseInt(value) / 100f;
							break;
						case 1:
							c.fillHeight = Integer.parseInt(value) / 100f;
							break;
						default:
							throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
						}
					}
				}

			} else if (name.equals("size")) {
				switch (values.size()) {
				case 2:
					value = values.get(0);
					if (value.length() > 0) c.minWidth = Integer.parseInt(value);
					value = values.get(1);
					if (value.length() > 0) c.minHeight = Integer.parseInt(value);
					break;
				case 1:
					value = values.get(0);
					if (value.length() > 0) c.minWidth = c.minHeight = Integer.parseInt(value);
					break;
				default:
					throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
				}

			} else if (name.equals("width")) {
				switch (values.size()) {
				case 3:
					value = values.get(0);
					if (value.length() > 0) c.maxWidth = Integer.parseInt(value);
				case 2:
					value = values.get(1);
					if (value.length() > 0) c.prefWidth = Integer.parseInt(value);
				case 1:
					value = values.get(0);
					if (value.length() > 0) c.minWidth = Integer.parseInt(value);
					break;
				default:
					throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
				}

			} else if (name.equals("height")) {
				switch (values.size()) {
				case 3:
					value = values.get(0);
					if (value.length() > 0) c.maxHeight = Integer.parseInt(value);
				case 2:
					value = values.get(1);
					if (value.length() > 0) c.prefHeight = Integer.parseInt(value);
				case 1:
					value = values.get(0);
					if (value.length() > 0) c.minHeight = Integer.parseInt(value);
					break;
				default:
					throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
				}

			} else if (name.equals("spacing") || name.equals("space")) {
				switch (values.size()) {
				case 4:
					value = values.get(3);
					if (value.length() > 0) c.spaceRight = Integer.parseInt(value);
				case 3:
					value = values.get(2);
					if (value.length() > 0) c.spaceBottom = Integer.parseInt(value);
				case 2:
					value = values.get(0);
					if (value.length() > 0) c.spaceTop = Integer.parseInt(value);
					value = values.get(1);
					if (value.length() > 0) c.spaceLeft = Integer.parseInt(value);
					break;
				case 1:
					c.spaceTop = c.spaceLeft = c.spaceBottom = c.spaceRight = Integer.parseInt(values.get(0));
					break;
				default:
					throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
				}

			} else if (name.equals("padding") || name.equals("pad")) {
				switch (values.size()) {
				case 4:
					value = values.get(3);
					if (value.length() > 0) c.padRight = Integer.parseInt(value);
				case 3:
					value = values.get(2);
					if (value.length() > 0) c.padBottom = Integer.parseInt(value);
				case 2:
					value = values.get(0);
					if (value.length() > 0) c.padTop = Integer.parseInt(value);
					value = values.get(1);
					if (value.length() > 0) c.padLeft = Integer.parseInt(value);
					break;
				case 1:
					c.padTop = c.padLeft = c.padBottom = c.padRight = Integer.parseInt(values.get(0));
					break;
				default:
					throw new IllegalArgumentException("Invalid number of values (" + values.size() + "): " + values);
				}

			} else if (name.startsWith("padding") || name.startsWith("pad")) {
				name = name.replace("padding", "").replace("pad", "");
				if (name.equals("top") || name.equals("t"))
					c.padTop = Integer.parseInt(values.get(0));
				else if (name.equals("left") || name.equals("l"))
					c.padLeft = Integer.parseInt(values.get(0));
				else if (name.equals("bottom") || name.equals("b"))
					c.padBottom = Integer.parseInt(values.get(0));
				else if (name.equals("right") || name.equals("r")) //
					c.padRight = Integer.parseInt(values.get(0));
				else
					throw new IllegalArgumentException("Unknown property.");

			} else if (name.startsWith("spacing") || name.startsWith("space")) {
				name = name.replace("spacing", "").replace("space", "");
				if (name.equals("top") || name.equals("t"))
					c.spaceTop = Integer.parseInt(values.get(0));
				else if (name.equals("left") || name.equals("l"))
					c.spaceLeft = Integer.parseInt(values.get(0));
				else if (name.equals("bottom") || name.equals("b"))
					c.spaceBottom = Integer.parseInt(values.get(0));
				else if (name.equals("right") || name.equals("r")) //
					c.spaceRight = Integer.parseInt(values.get(0));
				else
					throw new IllegalArgumentException("Unknown property.");

			} else if (name.equals("align")) {
				c.align = 0;
				for (int i = 0, n = values.size(); i < n; i++) {
					value = values.get(i);
					if (value.equals("center"))
						c.align |= BaseTableLayout.CENTER;
					else if (value.equals("left"))
						c.align |= BaseTableLayout.LEFT;
					else if (value.equals("right"))
						c.align |= BaseTableLayout.RIGHT;
					else if (value.equals("top"))
						c.align |= BaseTableLayout.TOP;
					else if (value.equals("bottom"))
						c.align |= BaseTableLayout.BOTTOM;
					else
						throw new IllegalArgumentException("Invalid value: " + value);
				}

			} else if (name.equals("ignore")) {
				c.ignore = values.size() == 0 ? true : Boolean.valueOf(values.get(0));

			} else if (name.equals("colspan")) {
				c.colspan = Integer.parseInt(values.get(0));

			} else if (name.equals("uniform")) {
				if (values.size() == 0) c.uniformWidth = c.uniformHeight = true;
				for (int i = 0, n = values.size(); i < n; i++) {
					value = values.get(i);
					if (value.equals("x"))
						c.uniformWidth = true;
					else if (value.equals("y"))
						c.uniformHeight = true;
					else if (value.equals("false"))
						c.uniformHeight = c.uniformHeight = null;
					else
						throw new IllegalArgumentException("Invalid value: " + value);
				}

			} else
				throw new IllegalArgumentException("Unknown property.");
		} catch (Exception ex) {
			throw new IllegalArgumentException("Error setting property: " + name, ex);
		}
		values.clear();
	}

	static private Object invokeMethod (Object object, String name, ArrayList<String> values) throws NoSuchMethodException {
		Method[] methods = object.getClass().getMethods();
		outer:
		for (int i = 0, n = methods.length; i < n; i++) {
			Method method = methods[i];
			if (!method.getName().equals(name)) continue;
			Object[] params = values.toArray();
			Class[] paramTypes = method.getParameterTypes();
			for (int ii = 0, nn = paramTypes.length; ii < nn; ii++) {
				Object value = convertType(object, (String)params[ii], paramTypes[ii]);
				if (value == null) continue outer;
				params[ii] = value;
			}
			try {
				return method.invoke(object, params);
			} catch (Exception ex) {
				throw new RuntimeException("Error invoking method: " + name, ex);
			}
		}
		throw new NoSuchMethodException();
	}

	static private Object convertType (Object parentObject, String value, Class paramType) {
		if (paramType == String.class) return value;
		try {
			if (paramType == int.class || paramType == Integer.class) return Integer.valueOf(value);
			if (paramType == float.class || paramType == Float.class) return Float.valueOf(value);
			if (paramType == long.class || paramType == Long.class) return Long.valueOf(value);
			if (paramType == double.class || paramType == Double.class) return Double.valueOf(value);
		} catch (NumberFormatException ignored) {
		}
		if (paramType == boolean.class || paramType == Boolean.class) return Boolean.valueOf(value);
		if (paramType == char.class || paramType == Character.class) return value.charAt(0);
		if (paramType == short.class || paramType == Short.class) return Short.valueOf(value);
		if (paramType == byte.class || paramType == Byte.class) return Byte.valueOf(value);
		// Look for a static field.
		try {
			Field field = paramType.getField(value);
			if (paramType == field.getType()) return field.get(null);
		} catch (Exception ignored) {
		}
		try {
			Field field = parentObject.getClass().getField(value);
			if (paramType == field.getType()) return field.get(null);
		} catch (Exception ignored) {
		}
		return null;
	}

	static private Object newWidget (String className) throws Exception {
		try {
			return Class.forName(className).newInstance();
		} catch (Exception ex) {
			for (int i = 0, n = BaseTableLayout.classPrefixes.size(); i < n; i++) {
				String prefix = BaseTableLayout.classPrefixes.get(i);
				try {
					return Class.forName(prefix + className).newInstance();
				} catch (Exception ignored) {
				}
			}
			throw ex;
		}
	}

	static public void main (String args[]) {
		BaseTableLayout table = new BaseTableLayout();
		table.setName("button", 123);
		table.setName("textbox", 345);
		table.setName("textbox2", 345);
		table.parse("<Meow>" //
			+ "width:400 height:400 " //
			+ "[boom:java.lang.String] <Booyah> size:80,80 align:left spacing:10 ( bean:true [button] moo (yagga:yo) 'sweet' ) \n " //
			+ "{ [textbox] [textbox] } " //
			+ "[textbox]\nalign:right,bottom \n ");
	}
}
