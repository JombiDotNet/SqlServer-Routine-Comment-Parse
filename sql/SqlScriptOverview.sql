

  DECLARE @lines TABLE
  (id int IDENTITY, line nvarchar(MAX))

  -- Cleanup the line and change tabs to two spaces.
  INSERT INTO @lines
  (line)
  SELECT value = REPLACE(dbo.pfLTrimX(dbo.pfRTrimX(value)), CHAR(9), '  ')
  FROM STRING_SPLIT(@routine_definition, CHAR(13))