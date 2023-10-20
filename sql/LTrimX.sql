SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		  Jim Richards
-- Create date: 5/1/2020
-- Description:	Remove leading white space, tabs, carriage returns, line feeds.
-- https://blog.sqlauthority.com/2008/10/10/sql-server-2008-enhenced-trim-function-remove-trailing-spaces-leading-spaces-white-space-tabs-carriage-returns-line-feeds/
-- Revisions:     5/1/2020    - First revision
--                10/20/2023  - Simplifies with a single PATINDEX
--                            - Old: One LIKE and a PATINDEX
--                            - New: One PATINDEX
-- =============================================
CREATE OR ALTER   FUNCTION [dbo].[LTrimX]
(
  @text nvarchar(MAX)
)
RETURNS nvarchar(MAX)
AS
BEGIN
  DECLARE @trim_chars varchar(10)
    , @trim_pos int

  SET @trim_chars = CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32)

  -- Find the first non-trim character
  SET @trim_pos = PATINDEX('%[^' + @trim_chars + ']%', @text)

  IF @trim_pos = 0 RETURN @text
  RETURN RIGHT(@text, LEN(@text) - @trim_pos + 1)
END
GO