SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		  Jim Richards
-- Create date: 5/1/2020
-- Description:	Remove trailing white space, tabs, carriage returns, line feeds.
-- https://blog.sqlauthority.com/2008/10/10/sql-server-2008-enhenced-trim-function-remove-trailing-spaces-leading-spaces-white-space-tabs-carriage-returns-line-feeds/
-- Revisions:     5/1/2020    - First revision
--                4/18/2022   - If NULL or Empty String, return NULL.
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[RTrimX]
(
  @character_expression nvarchar(4000)
)
RETURNS nvarchar(4000)
AS
BEGIN
  
  IF ISNULL(@character_expression, '') = ''
    RETURN NULL
  
  DECLARE @trimchars VARCHAR(10)
  SET @trimchars = CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32)
  IF @character_expression LIKE '%[' + @trimchars + ']'
    SET @character_expression = REVERSE(dbo.pfLTrimX(REVERSE(@character_expression)))
  RETURN @character_expression
END
GO