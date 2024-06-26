!-----------------------------------------------------------------------
      SUBROUTINE IP_SPLAT(IDRT,JMAX,SLAT,WLAT)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  SPLAT      COMPUTE LATITUDE FUNCTIONS
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-02-20
!
! ABSTRACT: COMPUTES COSINES OF COLATITUDE AND GAUSSIAN WEIGHTS
!           FOR ONE OF THE FOLLOWING SPECIFIC GLOBAL SETS OF LATITUDES.
!             GAUSSIAN LATITUDES (IDRT=4)
!             EQUALLY-SPACED LATITUDES INCLUDING POLES (IDRT=0)
!             EQUALLY-SPACED LATITUDES EXCLUDING POLES (IDRT=256)
!           THE GAUSSIAN LATITUDES ARE LOCATED AT THE ZEROES OF THE
!           LEGENDRE POLYNOMIAL OF THE GIVEN ORDER.  THESE LATITUDES
!           ARE EFFICIENT FOR REVERSIBLE TRANSFORMS FROM SPECTRAL SPACE.
!           (ABOUT TWICE AS MANY EQUALLY-SPACED LATITUDES ARE NEEDED.)
!           THE WEIGHTS FOR THE EQUALLY-SPACED LATITUDES ARE BASED ON
!           ELLSAESSER (JAM,1966).  (NO WEIGHT IS GIVEN THE POLE POINT.)
!           NOTE THAT WHEN ANALYZING GRID TO SPECTRAL IN LATITUDE PAIRS,
!           IF AN EQUATOR POINT EXISTS, ITS WEIGHT SHOULD BE HALVED.
!
! PROGRAM HISTORY LOG:
!   96-02-20  IREDELL
!
! USAGE:    CALL SPLAT(IDRT,JMAX,SLAT,WLAT)
!
!   INPUT ARGUMENT LIST:
!     IDRT     - INTEGER GRID IDENTIFIER
!                (IDRT=4 FOR GAUSSIAN GRID,
!                 IDRT=0 FOR EQUALLY-SPACED GRID INCLUDING POLES,
!                 IDRT=256 FOR EQUALLY-SPACED GRID EXCLUDING POLES)
!     JMAX     - INTEGER NUMBER OF LATITUDES.
!
!   OUTPUT ARGUMENT LIST:
!     SLAT     - REAL (JMAX) SINES OF LATITUDE.
!     WLAT     - REAL (JMAX) GAUSSIAN WEIGHTS.
!
! SUBPROGRAMS CALLED:
!   MINV         SOLVES FULL MATRIX PROBLEM
!
! REMARKS: FORTRAN 90 EXTENSIONS ARE USED.
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 77
!
!$$$
      REAL SLAT(JMAX),WLAT(JMAX)
      REAL PK(JMAX/2),PKM1(JMAX/2),PKM2(JMAX/2)
      PARAMETER(JZ=50)
      REAL BZ(JZ)
      DATA BZ        / 2.4048255577,  5.5200781103, &
       8.6537279129, 11.7915344391, 14.9309177086, 18.0710639679, &
      21.2116366299, 24.3524715308, 27.4934791320, 30.6346064684, &
      33.7758202136, 36.9170983537, 40.0584257646, 43.1997917132, &
      46.3411883717, 49.4826098974, 52.6240518411, 55.7655107550, &
      58.9069839261, 62.0484691902, 65.1899648002, 68.3314693299, &
      71.4729816036, 74.6145006437, 77.7560256304, 80.8975558711, &
      84.0390907769, 87.1806298436, 90.3221726372, 93.4637187819, &
      96.6052679510, 99.7468198587, 102.888374254, 106.029930916, &
      109.171489649, 112.313050280, 115.454612653, 118.596176630, &
      121.737742088, 124.879308913, 128.020877005, 131.162446275, &
      134.304016638, 137.445588020, 140.587160352, 143.728733573, &
      146.870307625, 150.011882457, 153.153458019, 156.295034268 /
      REAL AWORK((JMAX+1)/2,((JMAX+1)/2+1)),BWORK(((JMAX+1)/2)*2)
      PARAMETER(PI=3.14159265358979,C=(1.-(2./PI)**2)*0.25)
      PARAMETER(EPS=1.E-6)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  GAUSSIAN LATITUDES
      IF(IDRT.EQ.4) THEN
        JH=JMAX/2
        JHE=(JMAX+1)/2
        R=1./SQRT((JMAX+0.5)**2+C)
!$OMP PARALLEL DO PRIVATE(J) SCHEDULE(STATIC)
        DO J=1,MIN(JH,JZ)
          SLAT(J)=COS(BZ(J)*R)
        ENDDO
!$OMP PARALLEL DO PRIVATE(J) SCHEDULE(STATIC)
        DO J=JZ+1,JH
          SLAT(J)=COS((BZ(JZ)+(J-JZ)*PI)*R)
        ENDDO
        SPMAX=1.
        DO WHILE(SPMAX.GT.EPS)
          SPMAX=0.
          DO J=1,JH
            PKM1(J)=1.
            PK(J)=SLAT(J)
          ENDDO
          DO N=2,JMAX
            DO J=1,JH
              PKM2(J)=PKM1(J)
              PKM1(J)=PK(J)
              PK(J)=((2*N-1)*SLAT(J)*PKM1(J)-(N-1)*PKM2(J))/N
            ENDDO
          ENDDO
          DO J=1,JH
            SP=PK(J)*(1.-SLAT(J)**2)/(JMAX*(PKM1(J)-SLAT(J)*PK(J)))
            SLAT(J)=SLAT(J)-SP
            SPMAX=MAX(SPMAX,ABS(SP))
          ENDDO
        ENDDO
        DO J=1,JH
          WLAT(J)=(2.*(1.-SLAT(J)**2))/(JMAX*PKM1(J))**2
          SLAT(JMAX+1-J)=-SLAT(J)
          WLAT(JMAX+1-J)=WLAT(J)
        ENDDO
        IF(JHE.GT.JH) THEN
          SLAT(JHE)=0.
          WLAT(JHE)=2./JMAX**2
          DO N=2,JMAX,2
            WLAT(JHE)=WLAT(JHE)*N**2/(N-1)**2
          ENDDO
        ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  EQUALLY-SPACED LATITUDES INCLUDING POLES
      ELSE
          WRITE(*,*) "IP_SPLAT SHOULD BE CALLED WITH IDRT=4 not ", IDRT
	  STOP 10
      ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      RETURN
      END
