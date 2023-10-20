# SqlServer-Routine-Comment-Parse

Parser for Microsoft SQL Server Routine Comment Tags and Attributes

## Overview

When a new programmability object is created in Microsoft SQL Server, it adds comment lines containing Author, Create date, and Description tags. This project is was developed in order to parse this header section and return a table with information about the routine.

### Built-in Comments

```sql
-- =============================================
-- Author:    <Author>
-- Create date: <Create Date>
-- Description: <Description>
-- =============================================
```

## Assumptions

The parser assumes the attribute section starts and ends with a comment signifier (--) and at least one equal sign.

TODO: Add check if comment has an open, but not a close. Might check for CREATE, ALTER? Or use a `LEN(@text) - LEN(REPLACE(@text, '-- =', ''))` to see if there is more than one row.

## Generalized comments

After the initial release and more testing, it made sense to generalize instead of assuming Jim from five years ago followed the same tagging conventions.

### New tagging model

Line Structure | Description | Example
-- | --
\<Tag\>: \<Text\> | Simple Key/Value | Author or Description
\<Tag\>: \<Date\> | Simple Key/Value | Create date
-\<Text\> | (dash prefix) Additional note related to previous tag | Revision
\<Text\> | Additional note related to previous tag | Note or URL

### Things to check for

Rule | Handles
-- | --
Any semi-colon after the first semi-colon or a dash should be treated as part of text | "BUG FIX:" note in revision
A semi-colon must be followed by a space (or tab) | URLs

## Next Steps

- Create a function to find routine details such as
  - Lines of code
  - Number of comments (be sure to handle multi-line /\* \*/)
  - Number of blank lines
  - Contains updates, delete, insert of non-temporary tables (procedures)
  - Combines tabs and spaces

## Credits

Pinal Dave - [Enhanced TRIM() Function](https://blog.sqlauthority.com/2008/10/10/sql-server-2008-enhenced-trim-function-remove-trailing-spaces-leading-spaces-white-space-tabs-carriage-returns-line-feeds/)