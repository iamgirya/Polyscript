import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polyscript/model/actions/clear_text_action.dart';
import 'package:polyscript/model/editor_model.dart';
import 'package:polyscript/model/user_model.dart';
import 'package:polyscript/ui/editor/editor_bar.dart';
import 'package:polyscript/ui/editor/line/line_widget.dart';
import 'package:provider/provider.dart';
import '../../input_manager.dart';
import '../../model/actions/replace_text_action.dart';
import '../../model/actions/update_position_action.dart';
import 'editor_inherit.dart';

class TextEditorWidget extends StatefulWidget {
  const TextEditorWidget({Key? key}) : super(key: key);

  @override
  State<TextEditorWidget> createState() => _TextEditorWidgetState();
}

class _TextEditorWidgetState extends State<TextEditorWidget> {
  final ScrollController scrollController = ScrollController();

  var textEditorFocus = FocusNode();
  var editorHeight = 0.0;
  var preffereCursorPositionX = 0;
  var lastPresentedLineIndex = 0;

  late DateTime lastTapTime;
  late Point<int>? highlightStart;
  late EditorModel editor;

  @override
  void initState() {
    super.initState();
    lastTapTime = DateTime.now();
    scrollController.addListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    editor = EditorInherit.of(context).editor;
    editor.onUpdate = () {
      setState(() {});
    };

    return Scaffold(
      body: ChangeNotifierProvider.value(
        value: editor,
        child: Column(
          children: [
            EditorBar(key: GlobalKey()),
            Expanded(
              child: LayoutBuilder(
                builder: ((context, constraints) {
                  editorHeight = constraints.maxHeight;
                  return GestureDetector(
                    onTapDown: (details) {
                      textEditorFocus.requestFocus();
                      var cursorPosition = pixelPositionToCursorPosition(details.globalPosition);
                      if (cursorPosition != null) {
                        if (wasDoubleTap(cursorPosition)) {
                          selectWord(cursorPosition);
                        } else {
                          updateLocalUserPosition(cursorPosition);
                        }
                        lastTapTime = DateTime.now();
                      }
                    },
                    // начало выделение
                    onHorizontalDragStart: (details) {
                      editor.updateLocalUser(newSelection: null);
                      textEditorFocus.requestFocus();
                      highlightStart = pixelPositionToCursorPosition(details.globalPosition);
                    },
                    // начало выделение
                    onVerticalDragStart: (details) {
                      editor.updateLocalUser(newSelection: null);
                      textEditorFocus.requestFocus();
                      highlightStart = pixelPositionToCursorPosition(details.globalPosition);
                    },
                    // отображение выделения
                    onHorizontalDragUpdate: (details) {
                      updateSelection(details.globalPosition);
                    },
                    // отображение выделения
                    onVerticalDragUpdate: (details) {
                      updateSelection(details.globalPosition);
                    },
                    // конец выделения
                    onHorizontalDragEnd: (details) {
                      highlightStart = null;
                    },
                    // конец выделения
                    onVerticalDragEnd: (details) {
                      highlightStart = null;
                    },
                    child: KeyboardListener(
                      autofocus: true,
                      focusNode: textEditorFocus,
                      onKeyEvent: (keyEvent) {
                        processKeyEvent(keyEvent);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        itemCount: editor.file.lines.length,
                        itemBuilder: ((context, index) {
                          lastPresentedLineIndex = index;
                          return LineWidget(
                            key: editor.file.lines[index].second,
                            text: editor.file.lines[index].first,
                            index: index,
                            lineWidth: constraints.maxWidth,
                          );
                        }),
                        controller: scrollController,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool wasDoubleTap(Point<int> position) =>
      position == editor.localUser.cursorPosition && DateTime.now().difference(lastTapTime).inMilliseconds < 400;

  void selectWord(Point<int> position) {
    int startOfWord = editor.file.lines[position.y].first.substring(0, position.x).lastIndexOf(' ') + 1;
    int endOfWord = editor.file.lines[position.y].first.substring(position.x).indexOf(' ');
    if (endOfWord == -1) {
      endOfWord = editor.file.lines[position.y].first.length;
    } else {
      endOfWord += position.x;
    }
    editor.sendJSON(UpdatePositionAction(editor.localUser.name, Point(endOfWord, position.y)));
    editor.updateLocalUser(newSelection: Selection(Point(startOfWord, position.y), Point(endOfWord, position.y)));
    preffereCursorPositionX = endOfWord;
  }

  void updateSelection(Offset position) {
    var newPosition = pixelPositionToCursorPosition(position);

    if (highlightStart != null && newPosition != null) {
      editor.sendJSON(UpdatePositionAction(editor.localUser.name, newPosition));
      editor.updateLocalUser(newSelection: Selection(highlightStart!, newPosition));
      preffereCursorPositionX = newPosition.x;

      scrollListOnEdges();
    }
  }

  void updateLocalUserPosition(Point<int> newPosition) {
    editor.sendJSON(UpdatePositionAction(editor.localUser.name, newPosition));
    preffereCursorPositionX = newPosition.x;
  }

  void processKeyEvent(KeyEvent event) {
    if (event is! KeyUpEvent) {
      if (event.isCtrlVEvent) {
        pasteTextFromClipboard();
      } else if (event.isCtrlCEvent) {
        copyTextToClipboard();
      } else if (event.isChar) {
        editor.sendJSON(ReplaceTextAction(editor.localUser.name, [event.character!]));
      } else if (event.isDeleteEvent) {
        editor.sendJSON(ClearTextAction(editor.localUser.name));
      } else if (event.isNewLineEvent) {
        editor.sendJSON(ReplaceTextAction(editor.localUser.name, ["\n"]));
      } else if (event.isControl) {
        InputEventManager.isCtrlPressed = true;
      } else {
        keyboardNavigation(event);
      }
    } else {
      if (event.isControl) {
        InputEventManager.isCtrlPressed = false;
      }
    }
  }

  void pasteTextFromClipboard() {
    Clipboard.getData(Clipboard.kTextPlain).then(
      (value) => editor.sendJSON(ReplaceTextAction(editor.localUser.name, value!.text!.split("\n"))),
    );
  }

  void copyTextToClipboard() {
    String selectedText = editor.getSelectedText();
    if (selectedText != "") {
      Clipboard.setData(ClipboardData(text: selectedText));
    }
  }

  void keyboardNavigation(KeyEvent event) {
    if (event.isArrowRight) {
      if (editor.localUser.cursorPosition.x == editor.file.lines[editor.localUser.cursorPosition.y].first.length &&
          editor.localUser.cursorPosition.y < editor.file.lines.length - 1) {
        editor.sendJSON(
          UpdatePositionAction(editor.localUser.name, Point(0, editor.localUser.cursorPosition.y + 1)),
        );
        preffereCursorPositionX = editor.localUser.cursorPosition.x;
      } else {
        editor.sendJSON(
          UpdatePositionAction(
              editor.localUser.name, Point(editor.localUser.cursorPosition.x + 1, editor.localUser.cursorPosition.y)),
        );
      }
      preffereCursorPositionX = editor.localUser.cursorPosition.x;
    } else if (event.isArrowLeft) {
      if (editor.localUser.cursorPosition.x == 0 && editor.localUser.cursorPosition.y > 0) {
        editor.sendJSON(UpdatePositionAction(
            editor.localUser.name,
            Point(
              editor.file.lines[editor.localUser.cursorPosition.y - 1].first.length,
              editor.localUser.cursorPosition.y - 1,
            )));
        preffereCursorPositionX = editor.localUser.cursorPosition.x;
      } else {
        editor.sendJSON(UpdatePositionAction(
            editor.localUser.name, Point(editor.localUser.cursorPosition.x - 1, editor.localUser.cursorPosition.y)));
        preffereCursorPositionX = editor.localUser.cursorPosition.x;
      }
    } else if (event.isArrowUp) {
      if (editor.localUser.cursorPosition.y > 0) {
        Offset? cursorPosition = cursorPositionToPixelPosition(editor.localUser.cursorPosition);

        if (cursorPosition != null) {
          Point<int>? newCursorPosition = pixelPositionToCursorPosition(
            cursorPosition - const Offset(0, LineWidget.baseHeight),
          );

          if (newCursorPosition != null) {
            if (newCursorPosition != editor.localUser.cursorPosition) {
              editor.sendJSON(UpdatePositionAction(editor.localUser.name, newCursorPosition));
              preffereCursorPositionX = newCursorPosition.x;
            }

            scrollListOnEdges();
          }
        }
      }
    } else if (event.isArrowDown) {
      if (editor.localUser.cursorPosition.y < editor.file.lines.length - 1) {
        var currentLineState =
            (editor.file.lines[editor.localUser.cursorPosition.y].second.currentState as LineWidgetState);

        double yOffset = (currentLineState.isExistUnlocalUsersOnLine ? 20 : 0);

        Offset? cursorPosition = cursorPositionToPixelPosition(editor.localUser.cursorPosition);

        if (cursorPosition != null) {
          // вычисляем новое положение
          Point<int>? newCursorPosition = pixelPositionToCursorPosition(
            cursorPosition + Offset(0, LineWidget.baseHeight + yOffset),
          );

          if (newCursorPosition != null) {
            if (newCursorPosition != editor.localUser.cursorPosition) {
              editor.sendJSON(UpdatePositionAction(editor.localUser.name, newCursorPosition));
              preffereCursorPositionX = newCursorPosition.x;
            }

            scrollListOnEdges();
          }
        }
      }
    }
  }

  void scrollListOnEdges() {
    var cursorPosition = cursorPositionToPixelPosition(editor.localUser.cursorPosition);
    if (cursorPosition != null && cursorPosition.dy > editorHeight) {
      scrollController.animateTo(scrollController.offset + (cursorPosition.dy - editorHeight),
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
    }
    if (cursorPosition != null && cursorPosition.dy < 42 + 20) {
      scrollController.animateTo(scrollController.offset + cursorPosition.dy - 42 - 20,
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
    }
  }

  Point<int>? pixelPositionToCursorPosition(Offset pixelPosition) {
    var lineElement = findLineElementUnderPosition(pixelPosition);
    if (lineElement == null) {
      return null;
    }

    var lineState = lineElement.state as LineWidgetState;
    var frame = getElementBounds(lineElement);
    var positionInLine = Offset(
      pixelPosition.dx - frame.left - LineWidget.leftTextOffset,
      pixelPosition.dy - frame.top,
    );

    return Point<int>(
      lineState.getCursorOffset(positionInLine),
      (lineElement.widget as LineWidget).index,
    );
  }

  StatefulElement? findLineElementUnderPosition(Offset position) {
    var startSearchIndex = max(0, lastPresentedLineIndex - 200);
    var endSearchIndex = min(editor.file.lines.length, lastPresentedLineIndex + 200);

    for (int i = startSearchIndex; i < endSearchIndex; i++) {
      var element = editor.file.lines[i].second.currentContext as StatefulElement?;
      if (isPositionInWidget(element, position)) {
        return element;
      }
    }

    return null;
  }

  bool isPositionInWidget(StatefulElement? element, Offset position) {
    if (element == null) {
      return false;
    }

    var elementBounds = getElementBounds(element);
    return elementBounds.contains(position);
  }

  Rect getElementBounds(StatefulElement element) {
    var elementPosition = element.renderObject!.getTransformTo(null).getTranslation();
    var elementSize = element.renderObject!.paintBounds.size;

    return Rect.fromLTWH(elementPosition.x, elementPosition.y, elementSize.width, elementSize.height);
  }

  Offset? cursorPositionToPixelPosition(Point<int> cursorPosition) {
    var lineElement = editor.file.lines[cursorPosition.y].second.currentContext as StatefulElement?;

    if (lineElement != null) {
      var lineWidgetPosition = lineElement.renderObject!.getTransformTo(null).getTranslation().xy;
      var lineWidgetState = lineElement.state as LineWidgetState;

      var lineOffset = lineWidgetState.textPainter.getOffsetForCaret(
        TextPosition(offset: cursorPosition.x),
        Rect.zero,
      );

      return Offset(
        lineWidgetPosition.x + lineOffset.dx + LineWidget.leftTextOffset,
        lineWidgetPosition.y + lineOffset.dy,
      );
    }

    return null;
  }
}
