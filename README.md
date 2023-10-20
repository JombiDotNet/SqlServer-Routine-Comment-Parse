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

- Author
- Create date
- Description

## Expanded Comments

Several other tags have been implemented because that is what I use.

```sql
-- =============================================
-- Author:    <same>
-- Create date: <same>
-- Description: <same>
-- <Additional_Description>
-- Revisions: <Revision 1 Date> - <Revision 1 Note>
--                              - <Additional Revision 1 Note>
--            ...
--            <Revision N Date> - <Revision N Note>
-- TODO: <TODO Item 1>
--       <TODO Item N>
-- =============================================
```

