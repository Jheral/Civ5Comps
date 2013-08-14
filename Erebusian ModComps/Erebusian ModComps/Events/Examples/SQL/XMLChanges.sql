-- Insert SQL Rules Here 
ALTER TABLE Event_Options ADD COLUMN bOverrideTooltip INT DEFAULT '0';
ALTER TABLE Events ADD COLUMN Image TEXT;

UPDATE Events SET Image = 'testImage_290x120.dds' WHERE Type = 'EVENT_TESTING_JHERAL';

UPDATE Event_Options SET bOverrideTooltip = '0' WHERE Type = 'EVENT_TESTING_JHERAL_OPTION1';
UPDATE Event_Options SET bOverrideTooltip = '0' WHERE Type = 'EVENT_TESTING_JHERAL_OPTION4';
UPDATE Event_Options SET bOverrideTooltip = '1' WHERE Type = 'EVENT_TESTING_JHERAL_OPTION2';
UPDATE Event_Options SET bOverrideTooltip = '1' WHERE Type = 'EVENT_TESTING_JHERAL_OPTION3';