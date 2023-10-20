-- =============================================
-- Author:		  Jim Richards
-- Create date: 10/20/2023
-- Description:	Parser for Microsoft SQL Server Routine Comments
-- Revisions:   10/20/2023     - Initial Release
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[SqlCommentAttributes] 
(
  @script nvarchar(MAX)
)
RETURNS @results TABLE
( 
  id int IDENTITY
  , attribute_tag nvarchar(255)
  , attribute_value nvarchar(512)     -- Adjust as needed
  , attribute_date date
)
AS
BEGIN
  DECLARE @pos int

  SET @pos = PATINDEX('%--[ ' + CHAR(9) + ']==%', @script)

  -- If there is no attribute section, return null
  IF @pos = 0 RETURN

  DECLARE @line nvarchar(255)
    , @start bit = 0
    , @colon_pos int
    , @dash_pos int
    , @date_pos int
    , @date_end_pos int
    , @line_has_tag bit
    , @line_has_date bit
    , @line_value nvarchar(255)
    , @tag nvarchar(255)
    , @line_date date

  -- break up 
  DECLARE script_cursor CURSOR READ_ONLY FOR
    SELECT value
    FROM
    (
      SELECT value = REPLACE(dbo.LTrimX(dbo.RTrimX(value)), CHAR(9), '  ')
      FROM STRING_SPLIT(@script, CHAR(13))
    ) a
    WHERE value LIKE '--%'

  OPEN script_cursor

  FETCH NEXT FROM script_cursor
  INTO @line

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @pos = PATINDEX('-- ==%', @line)

    -- If the line designates the attributes section 
    -- Set @start = 1 if it is zero, otherwise break (done with comment attribute)
    IF @pos > 0
      IF @start = 0 SET @start = 1
      ELSE BREAK
    ELSE
    BEGIN
      IF @start = 1
      BEGIN
        -- Remove comment dashes and clean leading and trailing characters. 
        -- Only need to do LTrimX because RTrimX will have already occurred
        SET @line = dbo.LTrimX(RIGHT(@line, LEN(@line) - 2))
       
        SET @dash_pos = CHARINDEX('- ', @line)
      
        IF @dash_pos > 0
        BEGIN
          SET @line_value = TRIM(RIGHT(@line, LEN(@line) - @dash_pos))
          SET @line = LEFT(@line, @dash_pos - 1)
        END

        SET @colon_pos = PATINDEX('%: %', @line)
        SET @date_pos = PATINDEX('%[0-9]%/%/[0-9][0-9][0-9][0-9]%', @line)    -- for the purposes of this project, tag date end with a four digit year.

        -- If colon is found, set the tag
        IF @colon_pos > 0
        BEGIN
          SET @line_has_tag = 1
          SET @tag = LEFT(@line, @colon_pos - 1)
          SET @line = TRIM(RIGHT(@line, LEN(@line) - @colon_pos))
          SET @dash_pos = CHARINDEX('-', @line, @colon_pos)
          SET @date_pos = PATINDEX('%[0-9]%/%/[0-9][0-9][0-9][0-9]%', @line)
        END
        ELSE SET @line_has_tag = 0

        -- If a date if found, set the date
        IF @date_pos > 0
        BEGIN
          SET @line_has_date = 1
          SET @date_end_pos = PATINDEX('%/[0-9][0-9][0-9][0-9]%', @line) + 4

          SET @line_date = SUBSTRING(@line, @date_pos, @date_end_pos)

          SET @line = TRIM(RIGHT(@line, LEN(@line) - @date_end_pos))
          SET @dash_pos = CHARINDEX('-', @line, @colon_pos)
        END
        ELSE SET @line_has_date = 0

        INSERT INTO @results
        (attribute_tag, attribute_value, attribute_date)
        VALUES
        (@tag, ISNULL(@line_value, @line), @line_date)

      END
    END

    FETCH NEXT FROM script_cursor
    INTO @line

  END

  CLOSE script_cursor
  DEALLOCATE script_cursor

  RETURN
END
GO