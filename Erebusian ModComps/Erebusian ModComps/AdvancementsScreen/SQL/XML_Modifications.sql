
-- Add a PolicyBranchClass tag to the Policy Branch table
ALTER TABLE PolicyBranchTypes ADD COLUMN PolicyBranchClass TEXT;
ALTER TABLE PolicyBranchTypes ADD COLUMN PolicyBranchImage TEXT;
ALTER TABLE PolicyBranchTypes ADD COLUMN PolicyBranchIcon TEXT;

-- Add a TechTreeType tag to the Technologies table
ALTER TABLE Technologies ADD COLUMN TechTreeType TEXT;