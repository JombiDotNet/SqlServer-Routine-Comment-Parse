SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		  Jim Richards
-- Create date: 10/20/2023
-- Description:	Parser for Microsoft SQL Server Routine Comment attribute
-- Revisions:   10/20/2023     - Initial Release
-- TODO:        Handle triple attribute line.
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[pfGetRoutineAttribute] 
(
  @routine_definition nvarchar(MAX)
  , @attribute nvarchar(128)
)
RETURNS nvarchar(255)
AS
BEGIN

  -- If there is no attribute section, return null
  IF PATINDEX('%-- =%', @routine_definition) = 0 RETURN NULL

  DECLARE @attribute_line nvarchar(155)

  SELECT TOP 1 @attribute_line = REPLACE(value, CHAR(9), ' ')
  FROM
  (
    SELECT value = dbo.pfLTrimX(dbo.pfRTrimX(value)) 
    FROM STRING_SPLIT(@routine_definition, CHAR(13))
  ) a
  WHERE value LIKE CONCAT('--%', @attribute, ':%')

  DECLARE @delim_pos int = CHARINDEX(':', @attribute_line)

  IF @delim_pos = 0 RETURN NULL

  RETURN dbo.pfLTrimX(dbo.pfRTrimX(RIGHT(@attribute_line, LEN(@attribute_line) - @delim_pos)))
END
GO