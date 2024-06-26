 SUBROUTINE IPXWAFS3(IDIR, NUMPTS_THIN, NUMPTS_FULL, KM, NUM_OPT, OPT_PTS, &
                    IGDTLEN, IGDTMPL_THIN, DATA_THIN, IB_THIN, BITMAP_THIN,  &
                    IGDTMPL_FULL, DATA_FULL, IB_FULL, BITMAP_FULL, IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! $Revision: 74685 $
!
! SUBPROGRAM:  IPXWAFS3   EXPAND OR CONTRACT WAFS GRIDS
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM TRANSFORMS BETWEEN THE THINNED WAFS GRIDS
!           USED FOR TRANSMITTING TO THE AVIATION COMMUNITY
!           AND THEIR FULL EXPANSION AS USED FOR GENERAL INTERPOLATION
!           AND GRAPHICS.  THE THINNED WAFS GRIDS ARE LATITUDE-LONGITUDE
!           GRIDS WHERE THE NUMBER OF POINTS IN EACH ROW DECREASE
!           TOWARD THE POLE.  THIS INFORMATION IS STORED
!           IN THE GRIB 2 GRID DEFINITION TEMPLATE (SECTION 3) 
!           STARTING AT OCTET 73. THE FULL GRID COUNTERPARTS
!           HAVE AN EQUAL NUMBER OF POINTS PER ROW.
!           THE TRANSFORM BETWEEN THE FULL AND THINNED WAFS
!           GRID IS DONE BY NEAREST NEIGHBOR AND IS
!           NOT REVERSIBLE.  THIS ROUTINE WORKS WITH
!           BITMAPPED DATA.
!
! PROGRAM HISTORY LOG:
!   07-07-13  TROJAN   - INITIAL VERSION BASED ON IPXWAFS2
!   2015-JUL  GAYNO    - CONVERT TO GRIB 2
!
! USAGE:   CALL IPXWAFS3(IDIR, NUMPTS_THIN, NUMPTS_FULL, KM, NUM_OPT, OPT_PTS, &
!                   IGDTLEN, IGDTMPL_THIN, DATA_THIN, IB_THIN, BITMAP_THIN,  &
!                   IGDTMPL_FULL, DATA_FULL, IB_FULL, BITMAP_FULL, IRET)
!
!   INPUT ARGUMENT LIST:
!     IDIR         - INTEGER TRANSFORM OPTION
!                   (+1 TO EXPAND THINNED FIELDS TO FULL FIELDS)
!                   (-1 TO CONTRACT FULL FIELDS TO THINNED FIELDS)
!     NUMPTS_THIN  - INTEGER NUMBER OF GRID POINTS - THINNED GRID.  MUST BE
!                    3447.
!     NUMPTS_FULL  - INTEGER NUMBER OF GRID POINTS - FULL GRID. MUST
!                    BE 5329.
!     KM           - INTEGER NUMBER OF FIELDS TO TRANSFORM
!     NUM_OPT      - INTEGER NUMBER OF VALUES TO DESCRIBE THE THINNED
!                    GRID.  MUST BE 73.  DIMENSION OF ARRAY OPT_PTS.
!     OPT_PTS      - INTEGER (NUM_OPT) NUMBER OF GRID POINTS PER ROW -
!                    THINNED GRID - IF IDIR=+1
!     IGDTLEN      - INTEGER GRID DEFINTION TEMPLATE ARRAY LENGTH.  MUST BE
!                    19 FOR LAT/LON GRIDS. CORRESPONDS TO THE GFLD%IGDTLEN
!                    COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!                    SAME FOR THIN AND FULL GRIDS WHICH ARE BOTH LAT/LON.
!     IGDTMPL_THIN - INTEGER (IGDTLEN) GRID DEFINITION TEMPLATE ARRAY -
!                    THINNED GRID - IF IDIR=+1. CORRESPONDS TO THE
!                    GFLD%IGDTMPL COMPONENT OF THE NCEP G2 LIBRARY
!                    GRIDMOD DATA STRUCTURE (SECTION 3 INFO):
!                    (1):  SHAPE OF EARTH, OCTET 15
!                    (2):  SCALE FACTOR OF SPHERICAL EARTH RADIUS,
!                          OCTET 16
!                    (3):  SCALED VALUE OF RADIUS OF SPHERICAL EARTH,
!                          OCTETS 17-20
!                    (4):  SCALE FACTOR OF MAJOR AXIS OF ELLIPTICAL EARTH,
!                          OCTET 21
!                    (5):  SCALED VALUE OF MAJOR AXIS OF ELLIPTICAL EARTH,
!                          OCTETS 22-25
!                    (6):  SCALE FACTOR OF MINOR AXIS OF ELLIPTICAL EARTH,
!                          OCTET 26
!                    (7):  SCALED VALUE OF MINOR AXIS OF ELLIPTICAL EARTH,
!                          OCTETS 27-30
!                    (8):  SET TO MISSING FOR THINNED GRID., OCTS 31-34
!                    (9):  NUMBER OF POINTS ALONG A MERIDIAN, OCTS 35-38
!                    (10): BASIC ANGLE OF INITIAL PRODUCTION DOMAIN,
!                          OCTETS 39-42.
!                    (11): SUBDIVISIONS OF BASIC ANGLE, OCTETS 43-46
!                    (12): LATITUDE OF FIRST GRID POINT, OCTETS 47-50
!                    (13): LONGITUDE OF FIRST GRID POINT, OCTETS 51-54
!                    (14): RESOLUTION AND COMPONENT FLAGS, OCTET 55
!                    (15): LATITUDE OF LAST GRID POINT, OCTETS 56-59
!                    (16): LONGITUDE OF LAST GRID POINT, OCTETS 60-63
!                    (17): SET TO MISSING FOR THINNED GRID, OCTETS 64-67
!                    (18): J-DIRECTION INCREMENT, OCTETS 68-71
!                    (19): SCANNING MODE, OCTET 72
!     DATA_THIN    - REAL (NUMPTS_THIN,KM) THINNED GRID FIELDS IF IDIR=+1
!     IB_THIN      - INTEGER (KM) BITMAP FLAGS THINNED GRID - IF IDIR=+1
!     BITMAP_THIN  - LOGICAL (NUMPTS_THIN,KM) BITMAP FIELDS THIN GRID - IF IDIR=+1
!     IGDTMPL_FULL - INTEGER (IGDTLEN) GRID DEFINITION TEMPLATE ARRAY -
!                    FULL GRID - IF IDIR=-1. CORRESPONDS TO THE
!                    GFLD%IGDTMPL COMPONENT OF THE NCEP G2 LIBRARY
!                    GRIDMOD DATA STRUCTURE. SAME AS IGDTMPL_THIN
!                    EXCEPT:
!                    (8):  NUMBER OF POINTS ALONG A PARALLEL, OCTS 31-34
!                    (17): I-DIRECTION INCREMENT, OCTETS 64-67
!     DATA_FULL    - REAL (NUMPTS_FULL,KM) FULL GRID FIELDS IF IDIR=-1
!     IB_FULL      - INTEGER (KM) BITMAP FLAGS FULL GRID - IF IDIR=-1
!     BITMAP_FULL  - LOGICAL (NUMPTS_FULL,KM) BITMAP FIELDS FULL GRID - IF IDIR=-1
!
!   OUTPUT ARGUMENT LIST:
!     OPT_PTS      - INTEGER (NUM_OPT) NUMBER OF GRID POINTS PER ROW -
!                    THINNED GRID - IF IDIR=-1
!     IGDTMPL_THIN - INTEGER (IGDTLEN) GRID DEFINITION TEMPLATE ARRAY -
!                    THINNED GRID - IF IDIR=-1. CORRESPONDS TO THE
!                    GFLD%IGDTMPL COMPONENT OF THE NCEP G2 LIBRARY
!                    GRIDMOD DATA STRUCTURE.  DEFINED ABOVE.
!     DATA_THIN    - REAL (NUMPTS_THIN,KM) THINNED GRID FIELDS IF IDIR=-1
!     IB_THIN      - INTEGER (KM) BITMAP FLAGS THINNED GRID - IF IDIR=-1
!     BITMAP_THIN  - LOGICAL (NUMPTS_THIN,KM) BITMAP FIELDS THIN GRID - IF IDIR=-1
!     IGDTMPL_FULL - INTEGER (IGDTLEN) GRID DEFINITION TEMPLATE ARRAY -
!                    FULL GRID - IF IDIR=+1. CORRESPONDS TO THE
!                    GFLD%IGDTMPL COMPONENT OF THE NCEP G2 LIBRARY
!                    GRIDMOD DATA STRUCTURE.  DEFINED ABOVE.
!     DATA_FULL    - REAL (NUMPTS_FULL,KM) FULL GRID FIELDS IF IDIR=+1
!     IB_FULL      - INTEGER (KM) BITMAP FLAGS FULL GRID - IF IDIR=+1
!     BITMAP_FULL  - LOGICAL (NUMPTS_FULL,KM) BITMAP FIELDS FULL GRID - IF IDIR=+1
!     IRET         - INTEGER RETURN CODE
!                     0    SUCCESSFUL TRANSFORMATION
!                     1    IMPROPER GRID SPECIFICATION
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,               INTENT(IN   ) :: NUM_OPT
 INTEGER,               INTENT(INOUT) :: OPT_PTS(NUM_OPT)
 INTEGER,               INTENT(IN   ) :: IDIR, KM, NUMPTS_THIN, NUMPTS_FULL
 INTEGER,               INTENT(IN   ) :: IGDTLEN
 INTEGER,               INTENT(INOUT) :: IGDTMPL_THIN(IGDTLEN)
 INTEGER,               INTENT(INOUT) :: IGDTMPL_FULL(IGDTLEN)
 INTEGER,               INTENT(INOUT) :: IB_THIN(KM), IB_FULL(KM)
 INTEGER,               INTENT(  OUT) :: IRET
!
 LOGICAL(KIND=1),       INTENT(INOUT) :: BITMAP_THIN(NUMPTS_THIN,KM)
 LOGICAL(KIND=1),       INTENT(INOUT) :: BITMAP_FULL(NUMPTS_FULL,KM)
!
 REAL,                  INTENT(INOUT) :: DATA_THIN(NUMPTS_THIN,KM)
 REAL,                  INTENT(INOUT) :: DATA_FULL(NUMPTS_FULL,KM)
!
 INTEGER,               PARAMETER     :: MISSING=-1
!
 INTEGER                              :: SCAN_MODE, I, J, K, IDLAT, IDLON
 INTEGER                              :: IA, IB, IM, IM1, IM2, NPWAFS(73)
 INTEGER                              :: IS1, IS2, ISCAN, ISCALE
!
 LOGICAL                              :: TEST1, TEST2
!
 REAL                                 :: DLON, HI
 REAL                                 :: RAT1, RAT2, RLON1, RLON2
 REAL                                 :: WA, WB, X1, X2
!
 DATA NPWAFS/ &
       73, 73, 73, 73, 73, 73, 73, 73, 72, 72, 72, 71, 71, 71, 70,&
       70, 69, 69, 68, 67, 67, 66, 65, 65, 64, 63, 62, 61, 60, 60,&
       59, 58, 57, 56, 55, 54, 52, 51, 50, 49, 48, 47, 45, 44, 43,&
       42, 40, 39, 38, 36, 35, 33, 32, 30, 29, 28, 26, 25, 23, 22,&
       20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2/
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSFORM GDS
 IRET=0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  REG LAT/LON GRIDS HAVE 19 GDT ELEMENTS.
 IF (IGDTLEN /= 19 .OR. NUMPTS_THIN/=3447 .OR. NUMPTS_FULL/=5329) THEN
   IRET=1
   RETURN
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  EXPAND THINNED GDS TO FULL GDS
 IF(IDIR.GT.0) THEN
   SCAN_MODE=IGDTMPL_THIN(19)
   ISCALE=IGDTMPL_THIN(10)*IGDTMPL_THIN(11)
   IF(ISCALE==0) ISCALE=10**6
   IDLAT=NINT(1.25*FLOAT(ISCALE))
   TEST1=ALL(OPT_PTS==NPWAFS)
   TEST2=ALL(OPT_PTS==NPWAFS(73:1:-1))
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SOME CHECKS TO ENSURE THIS IS A WAFS GRID
   IF(SCAN_MODE==64 .AND. IGDTMPL_THIN(9)==73 .AND. &
      IDLAT==IGDTMPL_THIN(18) .AND. (TEST1 .OR. TEST2) ) THEN
     IGDTMPL_FULL=IGDTMPL_THIN
     IM=73
     IGDTMPL_FULL(8)=IM
     RLON1=FLOAT(IGDTMPL_FULL(13))/FLOAT(ISCALE)
     RLON2=FLOAT(IGDTMPL_FULL(16))/FLOAT(ISCALE)
     ISCAN=MOD(IGDTMPL_FULL(19)/128,2)
     HI=(-1.)**ISCAN
     DLON=HI*(MOD(HI*(RLON2-RLON1)-1+3600,360.)+1)/(IM-1)
     IGDTMPL_FULL(17)=NINT(DLON*FLOAT(ISCALE))
   ELSE
     IRET=1
   ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  CONTRACT FULL GDS TO THINNED GDS
 ELSEIF(IDIR.LT.0) THEN
   SCAN_MODE=IGDTMPL_FULL(19)
   ISCALE=IGDTMPL_FULL(10)*IGDTMPL_FULL(11)
   IF(ISCALE==0) ISCALE=10**6
   IDLAT=NINT(1.25*FLOAT(ISCALE))
   IDLON=IDLAT
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SOME CHECKS TO ENSURE THIS IS A WAFS GRID
   IF(SCAN_MODE==64 .AND. IGDTMPL_FULL(8)==73 .AND. IGDTMPL_FULL(9)==73 .AND. &
      NUM_OPT==73 .AND. IDLAT==IGDTMPL_FULL(18) .AND. IDLON==IGDTMPL_FULL(17))THEN
     IGDTMPL_THIN=IGDTMPL_FULL
     IGDTMPL_THIN(8)=MISSING
     IGDTMPL_THIN(17)=MISSING
     IF(IGDTMPL_THIN(12)==0) THEN  ! IS LATITUDE OF ROW 1 THE EQUATOR?
       OPT_PTS=NPWAFS
     ELSE
       OPT_PTS=NPWAFS(73:1:-1)
     ENDIF
   ELSE
     IRET=1
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSFORM FIELDS
 IF(IRET.EQ.0) THEN
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  EXPAND THINNED FIELDS TO FULL FIELDS
   IF(IDIR.EQ.1) THEN
     DO K=1,KM
       IS1=0
       IS2=0
       IB_FULL(K)=0
       DO J=1,IGDTMPL_FULL(9)
         IM1=OPT_PTS(J)
         IM2=IGDTMPL_FULL(8)
         RAT1=FLOAT(IM1-1)/FLOAT(IM2-1)
         DO I=1,IM2
           X1=(I-1)*RAT1+1
           IA=X1
           IA=MIN(MAX(IA,1),IM1-1)
           IB=IA+1
           WA=IB-X1
           WB=X1-IA
           IF(WA.GE.WB) THEN
             IF(IB_THIN(K).EQ.0.OR.BITMAP_THIN(IS1+IA,K)) THEN
               DATA_FULL(IS2+I,K)=DATA_THIN(IS1+IA,K)
               BITMAP_FULL(IS2+I,K)=.TRUE.
             ELSE
               DATA_FULL(IS2+I,K)=0.0
               BITMAP_FULL(IS2+I,K)=.FALSE.
               IB_FULL(K)=1
             ENDIF
           ELSE
             IF(IB_THIN(K).EQ.0.OR.BITMAP_THIN(IS1+IB,K)) THEN
               DATA_FULL(IS2+I,K)=DATA_THIN(IS1+IB,K)
               BITMAP_FULL(IS2+I,K)=.TRUE.
             ELSE
               DATA_FULL(IS2+I,K)=0.0
               BITMAP_FULL(IS2+I,K)=.FALSE.
               IB_FULL(K)=1
             ENDIF
           ENDIF
         ENDDO
         IS1=IS1+IM1
         IS2=IS2+IM2
       ENDDO
     ENDDO
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  CONTRACT FULL FIELDS TO THINNED FIELDS
   ELSEIF(IDIR.EQ.-1) THEN
     DO K=1,KM
       IS1=0
       IS2=0
       IB_THIN(K)=0
       DO J=1,IGDTMPL_FULL(9)
         IM1=OPT_PTS(J)
         IM2=IGDTMPL_FULL(8)
         RAT2=FLOAT(IM2-1)/FLOAT(IM1-1)
         DO I=1,IM1
           X2=(I-1)*RAT2+1
           IA=X2
           IA=MIN(MAX(IA,1),IM2-1)
           IB=IA+1
           WA=IB-X2
           WB=X2-IA
           IF(WA.GE.WB) THEN
             IF(IB_FULL(K).EQ.0.OR.BITMAP_FULL(IS2+IA,K)) THEN
               DATA_THIN(IS1+I,K)=DATA_FULL(IS2+IA,K)
               BITMAP_THIN(IS1+I,K)=.TRUE.
             ELSE
               DATA_THIN(IS1+I,K)=0.0
               BITMAP_THIN(IS1+I,K)=.FALSE.
               IB_THIN(K)=1
             ENDIF
           ELSE
             IF(IB_FULL(K).EQ.0.OR.BITMAP_FULL(IS2+IB,K)) THEN
               DATA_THIN(IS1+I,K)=DATA_FULL(IS2+IB,K)
               BITMAP_THIN(IS1+I,K)=.TRUE.
             ELSE
               DATA_THIN(IS1+I,K)=0.0
               BITMAP_THIN(IS1+I,K)=.FALSE.
               IB_THIN(K)=1
             ENDIF
           ENDIF
         ENDDO
         IS1=IS1+IM1
         IS2=IS2+IM2
       ENDDO
     ENDDO
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE IPXWAFS3
