SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		  Jim Richards
-- Create date: 10/20/2023
-- Description:	Parser for Microsoft SQL Server Routine Comments
-- Revisions:   10/20/2023     - Initial Release
-- TODO:        Generalize <tag>: <date> - <note> instead of hard coding revision and %date% check.
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[pfGetRoutineAttributes] 
(
  @routine_definition nvarchar(MAX)
)
RETURNS @results TABLE
( 
  id int IDENTITY
  , attribute_tag nvarchar(255)
  , attribute_value nvarchar(255)
  , attribute_date date
  ---- Debug fields
  --, line nvarchar(255)
  --, in_description bit
  --, in_revision bit
  --, colon_pos tinyint
  --, dash_pos tinyint
  --, date_pos tinyint
  --, revision_date date
)
AS
BEGIN

  -- If there is no attribute section, return null
  IF PATINDEX('%-- ==%', @routine_definition) = 0 RETURN

  DECLARE @lines TABLE
  (id int IDENTITY, line nvarchar(MAX))

  -- Cleanup the line and change tabs to two spaces.
  INSERT INTO @lines
  (line)
  SELECT value = REPLACE(dbo.pfLTrimX(dbo.pfRTrimX(value)), CHAR(9), '  ')
  FROM STRING_SPLIT(@routine_definition, CHAR(13))

  DECLARE @line nvarchar(155)
    , @start bit = 0
    , @description bit = 0
    , @revision bit = 0
    , @pos int
    , @tag nvarchar(255)
    , @last_tag nvarchar(255)
    , @tag_start int
    , @len int
    , @colon_pos tinyint
    , @dash_pos tinyint
    , @date_pos tinyint
    , @revision_date date

  DECLARE routine_cursor CURSOR FOR
    SELECT value
    FROM
    (
      SELECT value = dbo.pfLTrimX(dbo.pfRTrimX(value)) 
      FROM STRING_SPLIT(@routine_definition, CHAR(13))
    ) a
    WHERE value LIKE '--%'

  OPEN routine_cursor

  FETCH NEXT FROM routine_cursor
  INTO @line

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @pos = PATINDEX('-- ==%', @line)

    -- If the line designates the attributes section 
    -- Set @start = 1 if it is zero, otherwise break (done with list)
    IF @pos > 0
      IF @start = 0 SET @start = 1
      ELSE BREAK
    ELSE
    BEGIN
      -- Remove comment
      SET @line = dbo.pfLTrimX(dbo.pfRTrimX(SUBSTRING(@line, 3, 255)))
      
      SET @len = LEN(@line)

      SET @colon_pos = PATINDEX('%:[ ]%', @line)
      SET @dash_pos = CHARINDEX('-', @line)

      -- If the colon is found, set some flags
      IF @colon_pos > 0 AND @colon_pos < IIF(@dash_pos = 0, @len, @dash_pos)
      BEGIN
        SET @tag_start = PATINDEX('%[a-z]%', @line)

        SET @tag = SUBSTRING(@line, @tag_start, @colon_pos - @tag_start)

        IF @tag = 'Description'
        BEGIN
          SET @description = 1
          SET @revision = 0
        END

        -- Author:      Jim Richards
        -- Description:   Get the Product Manual page number from IDs
        IF @tag IN ('Author', 'Description')
          INSERT INTO @results 
          (attribute_tag, attribute_value
          --, line, in_description, in_revision, colon_pos, dash_pos, date_pos, revision_date -- Debug line
          ) 
          VALUES (@tag, dbo.pfLTrimX(dbo.pfRTrimX(RIGHT(@line, @len - @colon_pos)))
            --, @line, @description, @revision, @colon_pos, @dash_pos, @dash_pos, @revision_date -- Debug line
          )

        -- Create date:   10/3/2023
        ELSE IF @tag LIKE '%date%'
        BEGIN
          IF @dash_pos = 0
            INSERT INTO @results 
            (attribute_tag, attribute_value, attribute_date
            --, line, in_description, in_revision, colon_pos, dash_pos, date_pos, revision_date -- Debug line
            )
            VALUES (@tag, @tag, dbo.pfLTrimX(dbo.pfRTrimX(RIGHT(@line, @len - @colon_pos)))
            --, @line, @description, @revision, @colon_pos, @dash_pos, @dash_pos, @revision_date -- Debug line
            )

        END

        -- Revisions:     10/3/2023   - First revision
        ELSE IF @tag LIKE 'Revision%'
        BEGIN
          SET @description = 0
          SET @revision = 1
          
          SET @revision_date = dbo.pfLTrimX(dbo.pfRTrimX(SUBSTRING(@line, @colon_pos + 1, @len - @dash_pos + 2)))

          INSERT INTO @results 
          (attribute_tag, attribute_date, attribute_value
          --, line, in_description, in_revision, colon_pos, dash_pos, date_pos, revision_date -- Debug line
          )
          VALUES 
          ('Revision'
          , @revision_date
          , dbo.pfLTrimX(dbo.pfRTrimX(RIGHT(@line, @len - @dash_pos)))
          --, @line, @description, @revision, @colon_pos, @dash_pos, @dash_pos, @revision_date -- Debug line
          )
        END
        ELSE
          INSERT INTO @results 
          (attribute_tag, attribute_value)
          VALUES 
          ('unknown', @line)

        SET @last_tag = @tag
      END
      ELSE IF @dash_pos > 0 AND @revision = 1 -- colon was not found, see if there is a dash and we are in the revision section
      BEGIN
        --                            - BUG FIX: now increments by one if an odd number of previous pages.
        SET @date_pos = PATINDEX('%[0-9]%/%/[0-9][0-9][0-9][0-9]%', @line)

        -- If no date, part of a previous revision
        IF @date_pos > 0
          SET @revision_date = dbo.pfLTrimX(dbo.pfRTrimX(LEFT(@line, @dash_pos - 1)))

        INSERT INTO @results 
          (attribute_tag, attribute_date, attribute_value
          --, line, in_description, in_revision, colon_pos, dash_pos, date_pos, revision_date -- Debug line
          ) 
          VALUES 
          ('Revision'
          , @revision_date
          , dbo.pfLTrimX(dbo.pfRTrimX(RIGHT(@line, @len - @dash_pos)))
          --, @line, @description, @revision, @colon_pos, @dash_pos, @dash_pos, @revision_date -- Debug line
          )

      END
      ELSE
        -- no tag found, date not found, probably part of another note or a description.
        INSERT INTO @results 
        (attribute_tag, attribute_value
        --, line, in_description, in_revision, colon_pos, dash_pos, date_pos, revision_date -- Debug line
        )
        VALUES 
        (@last_tag, dbo.pfLTrimX(dbo.pfRTrimX(@line))
        --, @line, @description, @revision, @colon_pos, @dash_pos, @dash_pos, @revision_date -- Debug line
        )
    END
    
    FETCH NEXT FROM routine_cursor
    INTO @line

  END

  CLOSE routine_cursor
  DEALLOCATE routine_cursor

  RETURN
END
GO