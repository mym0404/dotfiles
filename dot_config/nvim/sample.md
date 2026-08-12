
# Comprehensive Markdown Features

This file demonstrates a wide range of Markdown features.
## Headings
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

## Text Formatting

This is a paragraph with **bold text** and *italic text*. You can also use ***bold and italic***.
Additionally, you can `strikethrough this text` using backticks.

## Blockquote

> This is a blockquote.
> It can span multiple lines.

## Lists

### Unordered List
*   Item 1
*   Item 2
    *   Nested item 2.1
    *   Nested item 2.2
*   Item 3

### Ordered List
1.  First item
2.  Second item
    1.  Nested ordered item 2.1
    2.  Nested ordered item 2.2
3.  Third item

## Code

### Inline Code
Here is some inline code: `print("Hello, World!")`.

### Code Block (Python)
```python
def factorial(n):
    if n == 0:
        return 1
    else:
        return n * factorial(n-1)

print(factorial(5))
```

### Code Block (JavaScript)
```javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
}

greet("Markdown");
```

## Horizontal Rule

---

## Links

Visit [Google](https://www.google.com).
This is a [relative link](another-page.md).

## Images

![Alt text for image](https://picsum.photos/200/300 "Optional title for image")

## Tables

| Header 1 | Header 2 | Header 3 |
| :------- | :------: | -------: |
| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |
| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |
| Row 3 Col 1 | Row 3 Col 2 | Row 3 Col 3 |

## Task List

- [x] Completed task
- [ ] Incomplete task
    - [x] Sub-task

## Footnotes

Here is some text with a footnote[^1].

[^1]: This is the content of the footnote.

