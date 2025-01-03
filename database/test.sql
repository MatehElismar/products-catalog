USE [TagShelf]
GO
/****** Object:  StoredProcedure [dbo].[uspCheckMetadataExists]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCheckMetadataExists]
    @TagId UNIQUEIDENTIFIER,
    @Name NVARCHAR(255)
AS
BEGIN
    -- Assuming the database uses a case-insensitive collation for the Name column
    IF EXISTS (
        SELECT 1
        FROM [dbo].[Metadata]
        WHERE [TagId] = @TagId
        AND LOWER([Name]) = LOWER(@Name)
    )
SELECT CAST(1 AS BIT) AS 'Exists'
    ELSE
SELECT CAST(0 AS BIT) AS 'Exists'
END
GO
/****** Object:  StoredProcedure [dbo].[uspCheckTagExists]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCheckTagExists]
    @CompanyId UNIQUEIDENTIFIER,
    @Name NVARCHAR(255)
AS
BEGIN
    -- Assuming the database uses a case-insensitive collation for the Name column
    IF EXISTS (
        SELECT 1
        FROM [dbo].[Tags]
        WHERE [CompanyId] = @CompanyId
        AND LOWER([Name]) = LOWER(@Name)
    )
SELECT CAST(1 AS BIT) AS 'Exists'
    ELSE
SELECT CAST(0 AS BIT) AS 'Exists'
END
GO
/****** Object:  StoredProcedure [dbo].[uspCreateDirectory]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspCreateDirectory]
    @parentFilePrefix NVARCHAR(MAX),
    @companyId UNIQUEIDENTIFIER    
AS
BEGIN
    SET NOCOUNT ON;

	--
	DECLARE @createdDirId UNIQUEIDENTIFIER;
	-- Enums
	DECLARE @Folder INT = 1;	
	-- Dates
	DECLARE @CreationDate DATETIME = GETDATE();
	DECLARE @UpdateDate DATETIME = GETDATE();

    IF (@parentFilePrefix IS NULL)
BEGIN
SELECT TOP 1 @createdDirId = Id
FROM Directories
WHERE LOWER(Source) = 'decomposed' AND CompanyId = @companyId;
END
ELSE
BEGIN
SELECT TOP 1 @createdDirId = Id
FROM Directories
WHERE LOWER(Name) = LOWER(@parentFilePrefix) AND CompanyId = @companyId;

IF (@createdDirId IS NULL)
BEGIN
            SET @createdDirId = NEWID();

INSERT INTO Directories (Id, Name, CompanyId, Type, Source, Icon, CreationDate, UpdateDate)
VALUES (@createdDirId, @parentFilePrefix, @companyId, @Folder, @parentFilePrefix, @Folder, @CreationDate, @UpdateDate);
END
END

SELECT @createdDirId
END
GO
/****** Object:  StoredProcedure [dbo].[uspDeleteCompanyData]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspDeleteCompanyData]
    @CompanyId uniqueidentifier
AS
BEGIN
    -- Enables error handling
BEGIN TRY
        -- Start the transaction
BEGIN TRANSACTION;

        -- Delete operations
DELETE FROM UserInfo WHERE User_Id IN (SELECT UserId FROM Users WHERE CompanyId = @CompanyId);
DELETE FROM AssociatedCompaniesTouser WHERE UserId IN (SELECT UserId FROM Users WHERE CompanyId = @CompanyId);
DELETE FROM UserRole WHERE UserId IN (SELECT UserId FROM Users WHERE CompanyId = @CompanyId);
DELETE FROM UserTag WHERE UserId IN (SELECT UserId FROM Users WHERE CompanyId = @CompanyId);
DELETE FROM Users WHERE CompanyId = @CompanyId;

DELETE FROM CloudSettings WHERE Company_Id = @CompanyId;
DELETE FROM AssociatedCompanies WHERE CompanyId = @CompanyId OR AssociatedCompanyId = @CompanyId;
DELETE FROM AssociatedCompaniesTouser WHERE AssociatedCompanyId = @CompanyId;
DELETE FROM Files WHERE CompanyId = @CompanyId;
DELETE FROM MetadataTemplate WHERE MetadataId IN (SELECT Id FROM Metadata WHERE TagId IN (SELECT Id FROM Tags WHERE CompanyId = @CompanyId));
DELETE FROM MetadataPattern WHERE MetadataId IN (SELECT Id FROM Metadata WHERE TagId IN (SELECT Id FROM Tags WHERE CompanyId = @CompanyId));
DELETE FROM Metadata WHERE TagId IN (SELECT Id FROM Tags WHERE CompanyId = @CompanyId);
DELETE FROM TagTemplates WHERE TagId IN (SELECT Id FROM Tags WHERE CompanyId = @CompanyId);
DELETE FROM Tags WHERE CompanyId = @CompanyId;
DELETE FROM Applications WHERE CompanyId = @CompanyId;
DELETE FROM Companies WHERE Id = @CompanyId;

-- If we reach this point, it means no errors occurred
-- Commit the transaction
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
        -- If an error occurs, roll back the transaction
ROLLBACK TRANSACTION;

        -- Capture and return error information
SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_STATE() AS ErrorState,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetChildren]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspGetChildren]
    @ParentId UNIQUEIDENTIFIER
AS
BEGIN
SELECT Files.Id,
       Files.FileName,
       Files.FileNameWithoutExtension,
       Files.BlobName,
       Files.BlobUrl,
       Files.FileSize,
       Files.CompanyId,
       Files.Status,
       Files.IsDuplicate,
       Files.DuplicateOriginId,
       Files.TagId,
       Tags.Name as TagName,
       Files.ProposedTagId,
       Files.ClassificationStatus,
       FileLogs.PageCount,
       FileLogs.PageNumber,
       Files.CreationDate,
       Files.UpdateDate
FROM Files
         INNER JOIN FileLogs ON Files.Id = FileLogs.FileId
         LEFT JOIN Tags ON Files.TagId = Tags.Id
WHERE Files.ParentId = @ParentId
ORDER BY FileLogs.PageNumber ASC
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetCloudSettingsByWebHookUrl]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[uspGetCloudSettingsByWebHookUrl]
    @WebHookUrl nvarchar(300)
AS
BEGIN
    SET NOCOUNT ON;

SELECT *
FROM [dbo].[CloudSettings]
WHERE [WebHookUrl] = @WebHookUrl;
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileCountByDateRange]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileCountByDateRange]
    @companyId UNIQUEIDENTIFIER,
    @startDate DATETIME,
    @endDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

SELECT COUNT(*)
FROM Files
WHERE CompanyId = @companyId
  AND CreationDate > @startDate
  AND CreationDate <= @endDate;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileCountByStatus]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileCountByStatus]
    @companyId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

SELECT Status, COUNT(*) AS Count
FROM Files
WHERE CompanyId = @companyId
GROUP BY Status;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileCountByStatusAndClassification]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileCountByStatusAndClassification]
    @companyId UNIQUEIDENTIFIER,
    @status INT,
    @classificationStatus INT    
AS
BEGIN
    SET NOCOUNT ON;

SELECT COUNT(*)
FROM Files
WHERE Status >= @status
  AND CompanyId = @companyId
  AND TagId IS NOT NULL
  AND ClassificationStatus = @classificationStatus;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileCountByStatusAndDirectory]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileCountByStatusAndDirectory]
    @companyId UNIQUEIDENTIFIER,
    @directoryId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

SELECT Status, COUNT(*) AS Count
FROM Files
WHERE CompanyId = @companyId AND DirectoryId = @directoryId
GROUP BY Status;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileCountByStatusAndProposedTag]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileCountByStatusAndProposedTag]
    @companyId UNIQUEIDENTIFIER,
    @fileStatus INT
AS
BEGIN
    SET NOCOUNT ON;

SELECT COUNT(*)
FROM Files
WHERE Status = @fileStatus
  AND CompanyId = @companyId
  AND ProposedTagId IS NOT NULL
  AND TagId = ProposedTagId;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileCountByTagStatusAndClassification]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileCountByTagStatusAndClassification]
    @fileStatus INT,
    @classificationStatus INT,
    @companyId UNIQUEIDENTIFIER,
    @tagId UNIQUEIDENTIFIER  
AS
BEGIN
    SET NOCOUNT ON;

SELECT COUNT(*)
FROM Files
WHERE Status >= @fileStatus
  AND CompanyId = @companyId
  AND TagId = @tagId
  AND ClassificationStatus = @classificationStatus;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFilesByDirectory]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFilesByDirectory]
    @page INT,
    @pageSize INT,
    @directoryId UNIQUEIDENTIFIER,
    @companyId UNIQUEIDENTIFIER,
    @isTag BIT
AS
BEGIN
    -- Calculate total records
SELECT COUNT(*)
FROM Files
WHERE Files.CompanyId = @companyId
  AND Files.DirectoryId = @directoryId;

-- Get paginated results
DECLARE @offset INT;
    SET @offset = (@page - 1) * @pageSize;

SELECT
    F.Id,
    F.[FileName] AS Name,
    F.BlobUrl AS URL,
    F.FileSize,
    F.[Status] AS FileStatus,
    F.UpdateDate,
    @isTag AS ParentIsTag,
    Job.Stage,
    Job.FileCount AS JobFileCount,
    Job.FinishedFiles AS JobFinishedFiles,
    Dir.[Type],
    Dir.Icon,
    CASE
        WHEN F.isParent = 1 THEN (SELECT COUNT(*) FROM Files AS C WHERE C.ParentId = F.Id)
        ELSE 0
        END AS ChildrenTotalCount,
    CASE
        WHEN F.isParent = 1 AND EXISTS (SELECT 1 FROM Files AS C WHERE C.ParentId = F.Id) THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
        END AS HasChildren
FROM Files AS F

         INNER JOIN Directories AS Dir
                    ON F.DirectoryId = Dir.Id

         LEFT JOIN Jobs as Job
                   ON F.JobId = Job.Id

WHERE F.CompanyId = @companyId
  AND F.DirectoryId = @directoryId
ORDER BY F.UpdateDate DESC
OFFSET @offset ROWS
    FETCH NEXT @pageSize ROWS ONLY;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileStatusCount]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetFileStatusCount]
    @companyId UNIQUEIDENTIFIER,
    @fileStatus INT
AS
BEGIN
    SET NOCOUNT ON;

SELECT COUNT(*)
FROM (
         SELECT Id, Status, CompanyId
         FROM Files
         WHERE Status = @fileStatus AND CompanyId = @companyId
     ) AS Subquery;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetFileValidationData]    Script Date: 11/5/2024 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Raúl Roa
-- Create Date: 2020-07-18
-- Update Date: 2022-09-17, 2024-11-05
-- Description: Retrieves data required for file data validation
-- =============================================
CREATE PROCEDURE [dbo].[uspGetFileValidationData]
(
    -- Add the parameters for the stored procedure here
    @fileId uniqueidentifier    
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @currentFileLogId UNIQUEIDENTIFIER;
	DECLARE @proposedTagId UNIQUEIDENTIFIER;    
	DECLARE @jobId UNIQUEIDENTIFIER;    
    DECLARE @manual INT;

	-- Get FileLogId and ProposedTagId
SELECT TOP 1 @manual = FileLogs.ManualClassification, @currentFileLogId = FileLogs.Id, @proposedTagId = FileLogs.ProposedTagId FROM FileLogs WHERE FileId = @fileId ORDER BY UpdateDate DESC

    IF (@manual = 1)
BEGIN
SELECT @proposedTagId = Files.TagId FROM Files WHERE Id = @fileId
END        

	-- FILE DATA
SELECT @JobId = Files.JobId FROM Files WHERE Id = @fileId
    IF (@jobId IS NULL)
BEGIN
SELECT Files.Id, Files.JobId, Files.CompanyId, Files.FileName, Files.IsDuplicate, Files.ManualClassification, Files.ClassificationScore, Files.ClassificationScoreAboveDeviation, Files.ContentType as ContentType, Files.CreationDate, Tags.Id as TagId, Tags.Name as TagName, Tags.CacheTemplateJson as TagCacheTemplate
FROM Files
         INNER JOIN Tags ON
    Files.TagId = Tags.Id
WHERE Files.Id = @fileId
END
ELSE
BEGIN
SELECT Files.Id, Files.JobId, Files.CompanyId, Jobs.WebRequestId, Files.FileName, Files.IsDuplicate, Files.ManualClassification, Files.ClassificationScore, Files.ClassificationScoreAboveDeviation, Files.ContentType as ContentType, Files.CreationDate, Tags.Id as TagId, Tags.Name as TagName, Tags.CacheTemplateJson as TagCacheTemplate
FROM Files
         INNER JOIN Tags ON
    Files.TagId = Tags.Id
         INNER JOIN Jobs ON
    Files.JobId = Jobs.Id
WHERE Files.Id = @fileId
END

	-- METADATA FIELDS
SELECT Metadata.Id, Metadata.Name, Metadata.DisplayText, Metadata.ReadOnly, Metadata.Hidden, Metadata.[Required], Metadata.SortingOrder, Metadata.DataType, Metadata.FixedOptions, Metadata.CreationDate FROM Metadata WHERE Metadata.TagId = @proposedTagId

-- METADATA FIELDS VALUES
SELECT MetadataValues.Id, MetadataValues.MetadataId, MetadataValues.Value, MetadataValues.ConvertedValue, MetadataValues.Confirmed, MetadataValues.ClassificationScore FROM MetadataValues WHERE MetadataValues.FileLogId = @currentFileLogId

-- EXTRACTED DATA FIELDS
SELECT ExtractedData.Id, ExtractedData.FileLogId, ExtractedData.Content, ExtractedData.Provider, ExtractedData.Orientation, ExtractedData.Rotate FROM ExtractedData
                                                                                                                                                          INNER JOIN FileLogs ON
    ExtractedData.FileLogId = FileLogs.Id
WHERE FileLogs.FileId = @fileId
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetModelByTrainingId]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[uspGetModelByTrainingId]
    @TrainingId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

SELECT [Id],
    [TrainingId],
    [CompanyId],
    [Name],
    [Algorithm],
    [Accuracy],
    [AreaUnderRocCurve],
    [AreaUnderPrecisionRecallCurve],
    [F1Score],
    [PositiveRecall],
    [NegativeRecall],
    [MicroAccuracy],
    [MacroAccuracy],
    [LogLoss],
    [LogLossReduction],
    [ConfusionMatrix],
    [CreationDate],
    [UpdateDate]
FROM [dbo].[Models]
WHERE [TrainingId] = @TrainingId
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetModelsByCompanyId]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[uspGetModelsByCompanyId]
    @CompanyId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

SELECT [Id],
    [TrainingId],
    [CompanyId],
    [Name],
    [Algorithm],
    [Size],
    [Accuracy],
    [AreaUnderRocCurve],
    [AreaUnderPrecisionRecallCurve],
    [F1Score],
    [PositiveRecall],
    [NegativeRecall],
    [MicroAccuracy],
    [MacroAccuracy],
    [LogLoss],
    [LogLossReduction],
    [ConfusionMatrix],
    [CreationDate],
    [UpdateDate]
FROM [dbo].[Models]
WHERE [CompanyId] = @CompanyId
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetModifiedMetadataValueLogCount]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetModifiedMetadataValueLogCount]
    @companyId UNIQUEIDENTIFIER,
	@valueChanged BIT
AS
BEGIN
    SET NOCOUNT ON;

SELECT COUNT(*)
FROM MetadataValueLogs mlv
         JOIN MetadataValues mv ON mlv.MetadataValue_Id = mv.Id
         JOIN Metadata md ON mv.MetadataId = md.Id
         JOIN Tags t ON md.TagId = t.Id
WHERE mlv.ValueChanged = @valueChanged
  AND t.CompanyId = @companyId;
END;
GO
/****** Object:  StoredProcedure [dbo].[uspGetTrainingsByCompanyId]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Creating the stored procedure with pagination
CREATE PROCEDURE [dbo].[uspGetTrainingsByCompanyId]
    @CompanyId uniqueidentifier  -- Parameter: Company ID for which to retrieve trainings    
AS
BEGIN
    SET NOCOUNT ON;  -- Turn off the message that shows the number of rows affected

    -- SQL query with OFFSET-FETCH clause for pagination
SELECT
    [Id],
    [CompanyId],
    [StartDate],
    [EndDate],
    [UserName],
    [Mappings],
    [Status],
    [TrainDataKey],
    [TestDataKey],
    [ExampleCount],
    [AmountOfClasses],
    [FailedErrorMessage],
    [CreationDate],
    [UpdateDate]
FROM
    [dbo].[Training]
WHERE
    [CompanyId] = @CompanyId
ORDER BY
    [Id] ASC  -- Ensuring a consistent order for pagination    
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetTrainingsByCompanyIdPaged]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Creating the stored procedure with pagination
CREATE PROCEDURE [dbo].[uspGetTrainingsByCompanyIdPaged]
    @CompanyId uniqueidentifier,  -- Parameter: Company ID for which to retrieve trainings
    @PageIndex int,              -- Parameter: Page index for pagination (0 based)
    @PageSize int                -- Parameter: Number of records per page
AS
BEGIN
    SET NOCOUNT ON;  -- Turn off the message that shows the number of rows affected

    -- SQL query with OFFSET-FETCH clause for pagination
SELECT
    [Id],
    [CompanyId],
    [StartDate],
    [EndDate],
    [UserName],
    [Status],
    [TrainDataKey],
    [TestDataKey],
    [ExampleCount],
    [AmountOfClasses],
    [FailedErrorMessage],
    [CreationDate],
    [UpdateDate]
FROM
    [dbo].[Training]
WHERE
    [CompanyId] = @CompanyId
ORDER BY
    [Id] ASC  -- Ensuring a consistent order for pagination
OFFSET
    @PageIndex * @PageSize ROWS  -- Skipping the previous pages
    FETCH NEXT
    @PageSize ROWS ONLY;  -- Limiting the number of rows returned
END
GO
/****** Object:  StoredProcedure [dbo].[uspHandleFileCreate]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspHandleFileCreate]
    @Id UNIQUEIDENTIFIER,
    @UserName NVARCHAR(255),    
    @BlobName NVARCHAR(255),
	@FileName NVARCHAR(255),
    @BlobUrl NVARCHAR(MAX),
	@SnapshotUrl NVARCHAR(MAX),
    @IsParent BIT,
    @Channel NVARCHAR(255),
	@FileStatus INT,
	@PageCount INT,
	@CurrentPage INT,
	@FileOriginType INT,
	@Metadata NVARCHAR(MAX),
	-- File Info
    @FileSize BIGINT,
    @ContentMD5 NVARCHAR(50),
    @ContentType NVARCHAR(255),
	-- Relationships
	@CompanyId UNIQUEIDENTIFIER,
	@InboxId UNIQUEIDENTIFIER,
	@SessionId UNIQUEIDENTIFIER = NULL,
    @ParentId UNIQUEIDENTIFIER = NULL,
    @DirectoryId UNIQUEIDENTIFIER = NULL,
    @JobId UNIQUEIDENTIFIER = NULL,
	-- Dates
	@CreationDate DATETIME,
	@UpdateDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Get existing file Id by MD5Hash
    DECLARE @ExistingFileId UNIQUEIDENTIFIER;
SELECT @ExistingFileId = Id
FROM Files
WHERE MD5Hash = @ContentMD5;

-- Insert FileLog
DECLARE @fileLogId UNIQUEIDENTIFIER;
    SET @fileLogId = NEWID();

	-- Default values
	DECLARE @ShouldBeClassified BIT = 1;
	DECLARE @ClassificationStatus INT = 0;	

	-- Parent checks
	IF @IsParent = 1
BEGIN
		SET @ShouldBeClassified = 0 -- Don't classify
		SET @ClassificationStatus = 2 -- NoTag
END	
    
    
    IF (@DirectoryId IS NOT NULL)
BEGIN        
        SET @ShouldBeClassified = 0 -- Don't classify
		SET @ClassificationStatus = 2 -- NoTag
		SET @InboxId = @DirectoryId
END
	
	-- Update directory update date
UPDATE Directories SET UpdateDate = @UpdateDate WHERE Id = @InboxId

                                                      -- Insert File
    INSERT INTO Files (Id, FileName, FileNameWithoutExtension, BlobName, BlobUrl, CompanyId, MD5Hash, ContentType, Channel, FileSize, JobId, DirectoryId, DeferredSessionId, IsParent, ParentId, Status, IsDataDuplicate, IsDuplicate, DuplicateOriginId, IsDuplicateByValues, ManualClassification, ShouldBeClassified, ClassificationStatus, ClassificationScore, ClassificationScoreAboveDeviation, ProposedTagVariance, InputType, Metadata, CreationDate, UpdateDate)
VALUES (@Id, dbo.GetFileName(@FileName), dbo.GetFileNameWithoutExtension(@FileName), @BlobName, @BlobUrl, @CompanyId, @ContentMD5, @ContentType, @Channel, @FileSize, @JobId, @InboxId, @SessionId, @IsParent, @ParentId, @FileStatus, 0, CASE WHEN @ExistingFileId IS NOT NULL THEN 1 ELSE 0 END, @ExistingFileId, 0, 0, @ShouldBeClassified, @ClassificationStatus, 0, 1, 0, @FileOriginType, @Metadata, @CreationDate, @UpdateDate);

-- Insert Log
INSERT INTO FileLogs (Id, SnapShotUrl, UserName, FileSize, MD5Hash, Channel, ContentType, FileId, PageCount, PageNumber, Retries, ExceededRetries, ClassificationScore, ClassificationStatus, ManualClassification
                     , CreationDate, UpdateDate)
VALUES (@fileLogId, @SnapshotUrl, @UserName, @FileSize, @ContentMD5, @Channel, @ContentType, @Id, @PageCount, @CurrentPage, 0, 0, 0, @ClassificationStatus, 0, @CreationDate, @UpdateDate);

-- Insert Journey
INSERT INTO Journey(Status, FileLogId, CreationDate, UpdateDate)
VALUES(@FileStatus, @fileLogId, @CreationDate, @UpdateDate)

-- Return the current added file Id
SELECT @Id
END

GO
/****** Object:  StoredProcedure [dbo].[uspRemoveJobFiles]    Script Date: 10/7/2024 7:23:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspRemoveJobFiles]
    @JobId UNIQUEIDENTIFIER,
    @DeleteLocalFiles BIT
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary table to store the files that need to be removed
CREATE TABLE #FilesToDelete (
                                FileId UNIQUEIDENTIFIER
);

-- Insert the file IDs into the temporary table
IF (@DeleteLocalFiles = 1)
BEGIN
INSERT INTO #FilesToDelete (FileId)
SELECT Id
FROM [Files]
WHERE JobId = @JobId;
END
ELSE
BEGIN
INSERT INTO #FilesToDelete (FileId)
SELECT Id
FROM [Files]
WHERE (DeferredSessionId IS NULL OR (ParentId IS NOT NULL AND DeferredSessionId IS NOT NULL))
  AND JobId = @JobId;
END;

    -- Remove extracted data, text annotations, metadata values, and file logs
DELETE FROM ExtractedData
WHERE FileLogId IN (SELECT Id FROM FileLogs WHERE FileId IN (SELECT FileId FROM #FilesToDelete));

DELETE FROM TextAnnotations
WHERE FileLogId IN (SELECT Id FROM FileLogs WHERE FileId IN (SELECT FileId FROM #FilesToDelete));

DELETE FROM MetadataValues
WHERE FileLogId IN (SELECT Id FROM FileLogs WHERE FileId IN (SELECT FileId FROM #FilesToDelete));

DELETE FROM FileLogs
WHERE FileId IN (SELECT FileId FROM #FilesToDelete);

-- If job is deferred, reset files
DECLARE @IsDeferred BIT;
    SET @IsDeferred = (
        SELECT TOP 1 1
        FROM Jobs
        WHERE Id = @JobId
        AND DeferredSessionId IS NOT NULL
    );

    IF (@IsDeferred = 1)
BEGIN
		--DELETE FROM ExtractedData
		--WHERE FileLogId IN (SELECT FileLogs.Id FROM FileLogs 
		--							INNER JOIN Files ON FileLogs.FileId = Files.Id
		--					WHERE Files.JobId = @JobId)
  --      DELETE FROM TextAnnotations
		--WHERE FileLogId IN (SELECT FileLogs.Id FROM FileLogs 
		--							INNER JOIN Files ON FileLogs.FileId = Files.Id
		--					WHERE Files.JobId = @JobId)

  --      DELETE FROM MetadataValues
		--WHERE FileLogId IN (SELECT FileLogs.Id FROM FileLogs 
		--							INNER JOIN Files ON FileLogs.FileId = Files.Id
		--					WHERE Files.JobId = @JobId)

		-- Fetch FileLogId values based on JobId and store them in a temporary table
SELECT FL.Id
INTO #FileLogsToDelete
FROM FileLogs FL
         INNER JOIN Files F ON FL.FileId = F.Id
WHERE F.JobId = @JobId

-- Delete records from ExtractedData where FileLogId is in the temporary table
DELETE FROM ExtractedData
WHERE FileLogId IN (SELECT Id FROM #FileLogsToDelete)

-- Delete records from TextAnnotations where FileLogId is in the temporary table
DELETE FROM TextAnnotations
WHERE FileLogId IN (SELECT Id FROM #FileLogsToDelete)
