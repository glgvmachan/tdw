USE poc
go

/*
   There are about 2 to 3 million PROJECTs and about 32+ million MEETINGs across these PROJECTs
   Given the volume of MEETINGs, and that these grow at a higher rate than PROJECTs these
   will be carried as a DEGENERATE DIMENSION on the fact tables, by a MEETING_KEY, which would pretty much be the 
   SURVEY_ID, MEETING_ID (for consultations), DOWNLOAD_ID (for transcripts), and so on for other products
   The FACT tables will have a surrogate key that will be their primary keys, the composite key made of all the 
   attributes that are foreign keys from the DIMENSION tables will not be used to physically implement uniqueness
*/



