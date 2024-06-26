 SUBROUTINE POLATES1(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
                     IGDTNUMO,IGDTMPLO,IGDTLENO, &
                     MI,MO,KM,IBI,LI,GI, &
                     NO,RLAT,RLON,IBO,LO,GO,IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! $Revision: 74685 $
!
! SUBPROGRAM:  POLATES1   INTERPOLATE SCALAR FIELDS (BICUBIC)
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM PERFORMS BICUBIC INTERPOLATION
!           FROM ANY GRID TO ANY GRID FOR SCALAR FIELDS.
!           BITMAPS ARE NOW ALLOWED EVEN WHEN INVALID POINTS ARE WITHIN
!           THE BICUBIC TEMPLATE PROVIDED THE MINIMUM WEIGHT IS REACHED. 
!           OPTIONS ALLOW CHOICES BETWEEN STRAIGHT BICUBIC (IPOPT(1)=0)
!           AND CONSTRAINED BICUBIC (IPOPT(1)=1) WHERE THE VALUE IS
!           CONFINED WITHIN THE RANGE OF THE SURROUNDING 16 POINTS.
!           ANOTHER OPTION IS THE MINIMUM PERCENTAGE FOR MASK,
!           I.E. PERCENT VALID INPUT DATA REQUIRED TO MAKE OUTPUT DATA,
!           (IPOPT(2)) WHICH DEFAULTS TO 50 (IF IPOPT(2)=-1).
!           BILINEAR USED WITHIN ONE GRID LENGTH OF BOUNDARIES.
!           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
!           THE CODE RECOGNIZES THE FOLLOWING PROJECTIONS, WHERE
!           "IGDTNUMI/O" IS THE GRIB 2 GRID DEFINTION TEMPLATE NUMBER
!           FOR THE INPUT AND OUTPUT GRIDS, RESPECTIVELY:
!             (IGDTNUMI/O=00) EQUIDISTANT CYLINDRICAL
!             (IGDTNUMI/O=01) ROTATED EQUIDISTANT CYLINDRICAL. "E" AND
!                             NON-"E" STAGGERED
!             (IGDTNUMI/O=10) MERCATOR CYLINDRICAL
!             (IGDTNUMI/O=20) POLAR STEREOGRAPHIC AZIMUTHAL
!             (IGDTNUMI/O=30) LAMBERT CONFORMAL CONICAL
!             (IGDTNUMI/O=40) GAUSSIAN CYLINDRICAL
!           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
!           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED.
!           ON THE OTHER HAND, THE OUTPUT CAN BE A SET OF STATION POINTS
!           IF IGDTNUMO<0, IN WHICH CASE THE NUMBER OF POINTS
!           AND THEIR LATITUDES AND LONGITUDES MUST BE INPUT.
!           OUTPUT BITMAPS WILL ONLY BE CREATED WHEN THE OUTPUT GRID
!           EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
!           THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
!        
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
! 1999-04-08  IREDELL  SPLIT IJKGDS INTO TWO PIECES
! 2001-06-18  IREDELL  INCLUDE MINIMUM MASK PERCENTAGE OPTION
! 2007-05-22  IREDELL  EXTRAPOLATE UP TO HALF A GRID CELL
! 2007-10-30  IREDELL  CORRECT NORTH POLE INDEXING PROBLEM,
!                      UNIFY MASKED AND NON-MASKED ALGORITHMS,
!                      AND SAVE WEIGHTS FOR PERFORMANCE.
! 2012-06-26  GAYNO    FIX OUT-OF-BOUNDS ERROR.  SEE NCEPLIBS
!                      TICKET #9.
! 2015-01-27  GAYNO    REPLACE CALLS TO GDSWIZ WITH NEW MERGED
!                      VERSION OF GDSWZD. 
! 2015-07-13  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAYS
!                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAYS.
!
! USAGE:    CALL POLATES1(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
!                         IGDTNUMO,IGDTMPLO,IGDTLENO, &
!                         MI,MO,KM,IBI,LI,GI, &
!                         NO,RLAT,RLON,IBO,LO,GO,IRET)
!
!   INPUT ARGUMENT LIST:
!     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
!                IPOPT(1)=0 FOR STRAIGHT BICUBIC;
!                IPOPT(1)=1 FOR CONSTRAINED BICUBIC WHERE VALUE IS
!                CONFINED WITHIN THE RANGE OF THE SURROUNDING 4 POINTS.
!                IPOPT(2) IS MINIMUM PERCENTAGE FOR MASK
!                (DEFAULTS TO 50 IF IPOPT(2)=-1)
!     IGDTNUMI - INTEGER GRID DEFINITION TEMPLATE NUMBER - INPUT GRID.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE:
!                  00 - EQUIDISTANT CYLINDRICAL
!                  01 - ROTATED EQUIDISTANT CYLINDRICAL.  "E"
!                       AND NON-"E" STAGGERED
!                  10 - MERCATOR CYCLINDRICAL
!                  20 - POLAR STEREOGRAPHIC AZIMUTHAL
!                  30 - LAMBERT CONFORMAL CONICAL
!                  40 - GAUSSIAN EQUIDISTANT CYCLINDRICAL
!     IGDTMPLI - INTEGER (IGDTLENI) GRID DEFINITION TEMPLATE ARRAY -
!                INPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE
!                (SECTION 3 INFO).  SEE COMMENTS IN ROUTINE
!                IPOLATES FOR COMPLETE DEFINITION.
!     IGDTLENI - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY - INPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTNUMO - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE. IGDTNUMO<0
!                MEANS INTERPOLATE TO RANDOM STATION POINTS.
!                OTHERWISE, SAME DEFINITION AS "IGDTNUMI".
!     IGDTMPLO - INTEGER (IGDTLENO) GRID DEFINITION TEMPLATE ARRAY -
!                OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!                (SECTION 3 INFO).  SEE COMMENTS IN ROUTINE
!                IPOLATES FOR COMPLETE DEFINITION.
!     IGDTLENO - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY - OUTPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
!                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
!     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
!                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
!     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
!     IBI      - INTEGER (KM) INPUT BITMAP FLAGS
!     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF SOME IBI(K)=1)
!     GI       - REAL (MI,KM) INPUT FIELDS TO INTERPOLATE
!     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF IGDTNUMO<0)
!     RLAT     - REAL (NO) OUTPUT LATITUDES IN DEGREES (IF IGDTNUMO<0)
!     RLON     - REAL (NO) OUTPUT LONGITUDES IN DEGREES (IF IGDTNUMO<0)
!
!   OUTPUT ARGUMENT LIST:
!     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF IGDTNUMO>=0)
!     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF IGDTNUMO>=0)
!     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF IGDTNUMO>=0)
!     IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
!     LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
!     GO       - REAL (MO,KM) OUTPUT FIELDS INTERPOLATED
!     IRET     - INTEGER RETURN CODE
!                0    SUCCESSFUL INTERPOLATION
!                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
!                3    UNRECOGNIZED OUTPUT GRID
!
! SUBPROGRAMS CALLED:
!   GDSWZD       GRID DESCRIPTION SECTION WIZARD
!   IJKGDS0      SET UP PARAMETERS FOR IJKGDS1
!   IJKGDS1      RETURN FIELD POSITION FOR A GIVEN GRID POINT
!   POLFIXS      MAKE MULTIPLE POLE SCALAR VALUES CONSISTENT
!   CHECK_GRIDS1 DETERMINE IF INPUT OR OUTPUT GRIDS HAVE CHANGED
!                BETWEEN CALLS TO THIS ROUTINE.
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
 USE GDSWZD_MOD
!
 IMPLICIT NONE
!
 INTEGER,        INTENT(IN   )         :: IGDTNUMI, IGDTLENI
 INTEGER,        INTENT(IN   )         :: IGDTMPLI(IGDTLENI)
 INTEGER,        INTENT(IN   )         :: IGDTNUMO, IGDTLENO
 INTEGER,        INTENT(IN   )         :: IGDTMPLO(IGDTLENO)
 INTEGER,                INTENT(IN   ) :: IPOPT(20)
 INTEGER,                INTENT(IN   ) :: MI,MO,KM
 INTEGER,                INTENT(IN   ) :: IBI(KM)
 INTEGER,                INTENT(INOUT) :: NO
 INTEGER,                INTENT(  OUT) :: IRET, IBO(KM)
!
 LOGICAL*1,              INTENT(IN   ) :: LI(MI,KM)
 LOGICAL*1,              INTENT(  OUT) :: LO(MO,KM)
!
 REAL,                   INTENT(IN   ) :: GI(MI,KM)
 REAL,                   INTENT(INOUT) :: RLAT(MO),RLON(MO)
 REAL,                   INTENT(  OUT) :: GO(MO,KM)
!
 REAL,                   PARAMETER     :: FILL=-9999.
!
 INTEGER                               :: IJKGDSA(20)
 INTEGER                               :: IJX(4),IJY(4)
 INTEGER                               :: MCON,MP,N,I,J,K
 INTEGER                               :: NK,NV,IJKGDS1
 INTEGER,            SAVE              :: NOX=-1,IRETX=-1
 INTEGER,            ALLOCATABLE,SAVE  :: NXY(:,:,:),NC(:)
!
 LOGICAL                               :: SAME_GRIDI, SAME_GRIDO
!
 REAL                                  :: PMP,XIJ,YIJ,XF,YF
 REAL                                  :: G,W,GMIN,GMAX
 REAL                                  :: WX(4),WY(4)
 REAL                                  :: XPTS(MO),YPTS(MO)
 REAL,               ALLOCATABLE,SAVE  :: RLATX(:),RLONX(:),WXY(:,:,:)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SET PARAMETERS
 IRET=0
 MCON=IPOPT(1)
 MP=IPOPT(2)
 IF(MP.EQ.-1.OR.MP.EQ.0) MP=50
 IF(MP.LT.0.OR.MP.GT.100) IRET=32
 PMP=MP*0.01
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 CALL CHECK_GRIDS1(IGDTNUMI,IGDTMPLI,IGDTLENI, &
                   IGDTNUMO,IGDTMPLO,IGDTLENO, &
                   SAME_GRIDI,SAME_GRIDO)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SAVE OR SKIP WEIGHT COMPUTATION
 IF(IRET.EQ.0.AND.(IGDTNUMO.LT.0.OR..NOT.SAME_GRIDI.OR..NOT.SAME_GRIDO))THEN
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  COMPUTE NUMBER OF OUTPUT POINTS AND THEIR LATITUDES AND LONGITUDES.
   IF(IGDTNUMO.GE.0) THEN
     CALL GDSWZD(IGDTNUMO,IGDTMPLO,IGDTLENO, 0,MO,FILL,XPTS,YPTS,RLON,RLAT,NO)
     IF(NO.EQ.0) IRET=3
   ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  LOCATE INPUT POINTS
   CALL GDSWZD(IGDTNUMI,IGDTMPLI,IGDTLENI,-1,NO,FILL,XPTS,YPTS,RLON,RLAT,NV)
   IF(IRET.EQ.0.AND.NV.EQ.0) IRET=2
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  ALLOCATE AND SAVE GRID DATA
   IF(NOX.NE.NO) THEN
     IF(NOX.GE.0) DEALLOCATE(RLATX,RLONX,NC,NXY,WXY)
     ALLOCATE(RLATX(NO),RLONX(NO),NC(NO),NXY(4,4,NO),WXY(4,4,NO))
     NOX=NO
   ENDIF
   IRETX=IRET
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  COMPUTE WEIGHTS
   IF(IRET.EQ.0) THEN
     CALL IJKGDS0(IGDTNUMI,IGDTMPLI,IGDTLENI,IJKGDSA)
!$OMP PARALLEL DO PRIVATE(N,XIJ,YIJ,IJX,IJY,XF,YF,J,I,WX,WY) SCHEDULE(STATIC)
     DO N=1,NO
       RLONX(N)=RLON(N)
       RLATX(N)=RLAT(N)
       XIJ=XPTS(N)
       YIJ=YPTS(N)
       IF(XIJ.NE.FILL.AND.YIJ.NE.FILL) THEN
         IJX(1:4)=FLOOR(XIJ-1)+(/0,1,2,3/)
         IJY(1:4)=FLOOR(YIJ-1)+(/0,1,2,3/)
         XF=XIJ-IJX(2)
         YF=YIJ-IJY(2)
         DO J=1,4
           DO I=1,4
             NXY(I,J,N)=IJKGDS1(IJX(I),IJY(J),IJKGDSA)
           ENDDO
         ENDDO
         IF(MINVAL(NXY(1:4,1:4,N)).GT.0) THEN
!  BICUBIC WHERE 16-POINT STENCIL IS AVAILABLE
           NC(N)=1
           WX(1)=XF*(1-XF)*(2-XF)/(-6.)
           WX(2)=(XF+1)*(1-XF)*(2-XF)/2.
           WX(3)=(XF+1)*XF*(2-XF)/2.
           WX(4)=(XF+1)*XF*(1-XF)/(-6.)
           WY(1)=YF*(1-YF)*(2-YF)/(-6.)
           WY(2)=(YF+1)*(1-YF)*(2-YF)/2.
           WY(3)=(YF+1)*YF*(2-YF)/2.
           WY(4)=(YF+1)*YF*(1-YF)/(-6.)
         ELSE
!  BILINEAR ELSEWHERE NEAR THE EDGE OF THE GRID
           NC(N)=2
           WX(1)=0
           WX(2)=(1-XF)
           WX(3)=XF
           WX(4)=0
           WY(1)=0
           WY(2)=(1-YF)
           WY(3)=YF
           WY(4)=0
         ENDIF
         DO J=1,4
           DO I=1,4
             WXY(I,J,N)=WX(I)*WY(J)
           ENDDO
         ENDDO
       ELSE
         NC(N)=0
       ENDIF
     ENDDO
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  INTERPOLATE OVER ALL FIELDS
 IF(IRET.EQ.0.AND.IRETX.EQ.0) THEN
   IF(IGDTNUMO.GE.0) THEN
     NO=NOX
     DO N=1,NO
       RLON(N)=RLONX(N)
       RLAT(N)=RLATX(N)
     ENDDO
   ENDIF
!$OMP PARALLEL DO PRIVATE(NK,K,N,G,W,GMIN,GMAX,J,I) SCHEDULE(STATIC)
   DO NK=1,NO*KM
     K=(NK-1)/NO+1
     N=NK-NO*(K-1)
     IF(NC(N).GT.0) THEN
       G=0
       W=0
       IF(MCON.GT.0) GMIN=HUGE(GMIN)
       IF(MCON.GT.0) GMAX=-HUGE(GMAX)
       DO J=NC(N),5-NC(N)
         DO I=NC(N),5-NC(N)
           IF(NXY(I,J,N).GT.0)THEN
             IF(IBI(K).EQ.0.OR.LI(NXY(I,J,N),K))THEN
               G=G+WXY(I,J,N)*GI(NXY(I,J,N),K)
               W=W+WXY(I,J,N)
               IF(MCON.GT.0) GMIN=MIN(GMIN,GI(NXY(I,J,N),K))
               IF(MCON.GT.0) GMAX=MAX(GMAX,GI(NXY(I,J,N),K))
             ENDIF
           ENDIF
         ENDDO
       ENDDO
       LO(N,K)=W.GE.PMP
       IF(LO(N,K)) THEN
         GO(N,K)=G/W
         IF(MCON.GT.0) GO(N,K)=MIN(MAX(GO(N,K),GMIN),GMAX)
       ELSE
         GO(N,K)=0.
       ENDIF
     ELSE
       LO(N,K)=.FALSE.
       GO(N,K)=0.
     ENDIF
   ENDDO
   DO K=1,KM
     IBO(K)=IBI(K)
     IF(.NOT.ALL(LO(1:NO,K))) IBO(K)=1
   ENDDO
   IF(IGDTNUMO.EQ.0) CALL POLFIXS(NO,MO,KM,RLAT,IBO,LO,GO)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 ELSE
   IF(IRET.EQ.0) IRET=IRETX
   IF(IGDTNUMO.GE.0) NO=0
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE POLATES1
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 SUBROUTINE CHECK_GRIDS1(IGDTNUMI,IGDTMPLI,IGDTLENI, &
                         IGDTNUMO,IGDTMPLO,IGDTLENO, &
                         SAME_GRIDI, SAME_GRIDO)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  CHECK_GRIDS1   CHECK GRID INFORMATION
!   PRGMMR: GAYNO       ORG: W/NMC23       DATE: 2015-07-13
!
! ABSTRACT: DETERMINE WHETHER THE INPUT OR OUTPUT GRID SPECS
!           HAVE CHANGED.
!
! PROGRAM HISTORY LOG:
! 2015-07-13  GAYNO     INITIAL VERSION
!
! USAGE:  CALL CHECK_GRIDS1(IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO, &
!                           IGDTLENO, SAME_GRIDI, SAME_GRIDO)
!   INPUT ARGUMENT LIST:
!     IGDTNUMI - INTEGER GRID DEFINITION TEMPLATE NUMBER - INPUT GRID.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTMPLI - INTEGER (IGDTLENI) GRID DEFINITION TEMPLATE ARRAY -
!                INPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTLENI - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY - INPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTNUMO - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
!                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTMPLO - INTEGER (IGDTLENO) GRID DEFINITION TEMPLATE ARRAY -
!                OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     IGDTLENO - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                TEMPLATE ARRAY - OUTPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
!                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!
!   OUTPUT ARGUMENT LIST:
!     SAME_GRIDI  - WHEN TRUE, THE INPUT GRID HAS NOT CHANGED BETWEEN CALLS.
!     SAME_GRIDO  - WHEN TRUE, THE OUTPUT GRID HAS NOT CHANGED BETWEEN CALLS.
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,        INTENT(IN   ) :: IGDTNUMI, IGDTLENI
 INTEGER,        INTENT(IN   ) :: IGDTMPLI(IGDTLENI)
 INTEGER,        INTENT(IN   ) :: IGDTNUMO, IGDTLENO
 INTEGER,        INTENT(IN   ) :: IGDTMPLO(IGDTLENO)
!
 INTEGER, SAVE                 :: IGDTNUMI_SAVE=-9999
 INTEGER, SAVE                 :: IGDTLENI_SAVE=-9999
 INTEGER, SAVE                 :: IGDTMPLI_SAVE(1000)=-9999
 INTEGER, SAVE                 :: IGDTNUMO_SAVE=-9999
 INTEGER, SAVE                 :: IGDTLENO_SAVE=-9999
 INTEGER, SAVE                 :: IGDTMPLO_SAVE(1000)=-9999
!
 LOGICAL,        INTENT(  OUT) :: SAME_GRIDI, SAME_GRIDO
!
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 SAME_GRIDI=.FALSE.
 IF(IGDTNUMI==IGDTNUMI_SAVE)THEN
   IF(IGDTLENI==IGDTLENI_SAVE)THEN
     IF(ALL(IGDTMPLI==IGDTMPLI_SAVE(1:IGDTLENI)))THEN
       SAME_GRIDI=.TRUE.
     ENDIF
   ENDIF
 ENDIF
!
 IGDTNUMI_SAVE=IGDTNUMI
 IGDTLENI_SAVE=IGDTLENI
 IGDTMPLI_SAVE(1:IGDTLENI)=IGDTMPLI
 IGDTMPLI_SAVE(IGDTLENI+1:1000)=-9999
!
 SAME_GRIDO=.FALSE.
 IF(IGDTNUMO==IGDTNUMO_SAVE)THEN
   IF(IGDTLENO==IGDTLENO_SAVE)THEN
     IF(ALL(IGDTMPLO==IGDTMPLO_SAVE(1:IGDTLENO)))THEN
       SAME_GRIDO=.TRUE.
     ENDIF
   ENDIF
 ENDIF
!
 IGDTNUMO_SAVE=IGDTNUMO
 IGDTLENO_SAVE=IGDTLENO
 IGDTMPLO_SAVE(1:IGDTLENO)=IGDTMPLO
 IGDTMPLO_SAVE(IGDTLENO+1:1000)=-9999
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE CHECK_GRIDS1
