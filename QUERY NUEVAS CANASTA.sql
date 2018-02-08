
USE DATAMARTCOMCHILE
GO

Declare @CampanaExito char(6)
Declare @CampanaFinCosecha char(6)
Declare @Campana_1 char(6)
Declare @Campana_2 char(6)
Declare @Campana_3 char(6)
Declare @Campana_4 char(6)
Declare @CampanaInicioCosecha char(6)

DECLARE @INICIOMenos6 as char(6)
DECLARE @INICIOMenos5 as char(6)
DECLARE @INICIOMenos4 as char(6)
DECLARE @INICIOMenos3 as char(6)
DECLARE @INICIOMenos2 as char(6)
DECLARE @INICIOMenos1 as char(6)
DECLARE @CampanaInicioCosechaMas1 as char(6)
DECLARE @CampanaInicioCosechaMas2 as char(6)
DECLARE @CampanaInicioCosechaMas3 as char(6)
DECLARE @CampanaInicioCosechaMas4 as char(6)
DECLARE @CampanaInicioCosechaMas5 as char(6)
DECLARE @CampanaInicioCosechaMas6 as char(6)
--Declare @CampanaC18 char(6)

Set @CampanaExito = '201714';
Set @CampanaFinCosecha = dbo.CalculaAnioCampana(@CampanaExito, -1)
Set @Campana_4 = dbo.CalculaAnioCampana(@CampanaFinCosecha, -1)
Set @Campana_3 = dbo.CalculaAnioCampana(@CampanaFinCosecha, -2)
Set @Campana_2 = dbo.CalculaAnioCampana(@CampanaFinCosecha, -3)
Set @Campana_1 = dbo.CalculaAnioCampana(@CampanaFinCosecha, -4)
Set @CampanaInicioCosecha = dbo.CalculaAnioCampana(@CampanaFinCosecha, -5)

Set @INICIOMenos6 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, -6)
Set @INICIOMenos5 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, -5)
Set @INICIOMenos4 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, -4)
Set @INICIOMenos3 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, -3)
Set @INICIOMenos2 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, -2)
Set @INICIOMenos1 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, -1)
Set @CampanaInicioCosechaMas1 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, 1)
Set @CampanaInicioCosechaMas2 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, 2)
Set @CampanaInicioCosechaMas3 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, 3)
Set @CampanaInicioCosechaMas4 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, 4)
Set @CampanaInicioCosechaMas5 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, 5)
Set @CampanaInicioCosechaMas6 = dbo.CalculaAnioCampana(@CampanaInicioCosecha, 6)
--Set @CampanaC18 = dbo.CalculaAnioCampana(@CampanaExito, +17)

---------------------------------
-- 0. CONSULTORAS NUEVAS PURAS --
---------------------------------

if object_id ('tempdb..#CONSULTORAS') is not null drop table #CONSULTORAS
SELECT c.pkebelista
into #CONSULTORAS
FROM (select b.pkebelista, b.aniocampana, 
		CASE
			WHEN b.aniocampana = (select min(aniocampana) from fstaebecamc01 where pkebelista=b.pkebelista)
				and b.codstatus<>0 and b.codstatus <> 1 then 1
			WHEN b.codstatus = 1 THEN 1
			ELSE 0		  
		END AS flagNueva
	  from fstaebecamc01 b inner join
	  (select a.pkebelista, a.AnioCampana
	   from fstaebecamc01 a
	   inner join debelista b on a.pkebelista = b.pkebelista and a.aniocampana = b.aniocampanaprimerpedido
	   where a.AnioCampana = @CampanaInicioCosecha and a.CodStatus=1) 
	  AS d on b.pkebelista = d.pkebelista and b.aniocampana <= d.aniocampana)  AS c
GROUP BY c.pkebelista
HAVING SUM(c.flagNueva) = 1

--select * from #CONSULTORAS

--- INFO CAMPAÑA C07--------
IF OBJECT_ID ('TEMPDB..#FSTAEBECAMC01') IS NOT NULL DROP TABLE #FSTAEBECAMC01
SELECT A.*,c.codebelista
,Datediff(YY, c.FechaNacimiento, getdate()) as Edad
INTO #FSTAEBECAMC01
FROM FSTAEBECAMC01 A
INNER JOIN #CONSULTORAS B ON A.PKEbelista=B.PKEbelista
inner join debelista c on b.PKEbelista=c.PKEbelista
WHERE ANIOCAMPANA BETWEEN @CampanaInicioCosecha AND @CampanaExito

IF OBJECT_ID ('TEMPDB..#AUX') IS NOT NULL DROP TABLE #AUX
SELECT 
	PKEBELISTA, 
	isnull([CI],0) as CI,
	isnull([CIM1],0) as CIM1,
	isnull([CIM2],0) as CIM2,
	isnull([CIM3],0) as CIM3,
	isnull([CIM4],0) as CIM4,
	isnull([CIM5],0) as CIM5
into #AUX
FROM
(SELECT PKEBELISTA, CODCOMPORTAMIENTOROLLING,
		CASE ANIOCAMPANA 
			WHEN @CampanaInicioCosecha THEN 'CI'
			WHEN @CampanaInicioCosechaMas1 THEN 'CIM1'
			WHEN @CampanaInicioCosechaMas2 THEN 'CIM2'
			WHEN @CampanaInicioCosechaMas3 THEN 'CIM3'
			WHEN @CampanaInicioCosechaMas4 THEN 'CIM4'
			WHEN @CampanaInicioCosechaMas5 THEN 'CIM5'
		END AS CAMPANA
    FROM FSTAEBECAMC01 WHERE ANIOCAMPANA BETWEEN @CampanaInicioCosecha AND @CampanaFinCosecha) AS SourceTable
PIVOT
(
MAX([CODCOMPORTAMIENTOROLLING])
FOR CAMPANA IN ([CI],[CIM1],[CIM2],[CIM3],[CIM4],[CIM5])
) AS PivotTable

IF OBJECT_ID ('TEMPDB..#FSTAEBECAMC01_2') IS NOT NULL DROP TABLE #FSTAEBECAMC01_2
select A.*,
CASE WHEN 
(((A.ANIOCAMPANA = @INICIOMenos6 AND CodStatus=1) AND (B.CI IN (2,3,4,5)))
	OR ((A.ANIOCAMPANA = @INICIOMenos5 AND CodStatus=1) AND (B.CIM1 IN (2,3,4,5)))  
	OR ((A.ANIOCAMPANA = @INICIOMenos4 AND CodStatus=1) AND (B.CIM2 IN (2,3,4,5)))
	OR ((A.ANIOCAMPANA = @INICIOMenos3 AND CodStatus=1) AND (B.CIM3 IN (2,3,4,5)))
	OR ((A.ANIOCAMPANA = @INICIOMenos2 AND CodStatus=1) AND (B.CIM4 IN (2,3,4,5)))
	OR ((A.ANIOCAMPANA = @INICIOMenos1 AND CodStatus=1) AND (B.CIM5 IN (2,3,4,5))))
THEN 1 else 0 end AS flagExito
into #FSTAEBECAMC01_2
from FSTAEBECAMC01 A
INNER JOIN #AUX B ON A.PKEBELISTA = B.PKEBELISTA 
WHERE A.AnioCampana BETWEEN @INICIOMenos6 AND @CampanaFinCosecha --12 CAMPAÑAS
-- 8096142

IF OBJECT_ID ('TEMPDB..#CONTEOPALANCAS') IS NOT NULL DROP TABLE #CONTEOPALANCAS
SELECT A.PKEBELISTA, A.ANIOCAMPANA, sum(case when pkpalanca>0 then 1 else 0 end) as NUMPALANCAS
INTO #CONTEOPALANCAS
FROM FResultadoPalancas A
RIGHT JOIN #CONSULTORAS B ON A.PKEBELISTA = B.PKEBELISTA
WHERE A.ANIOCAMPANA BETWEEN @CampanaInicioCosecha AND @CampanaFinCosecha
GROUP BY A.PKEBELISTA, A.ANIOCAMPANA

IF OBJECT_ID ('TEMPDB..#FVTAPROEBECAMC01') IS NOT NULL DROP TABLE #FVTAPROEBECAMC01
SELECT A.*
INTO #FVTAPROEBECAMC01
FROM FVTAPROEBECAMC01 A
INNER JOIN #CONSULTORAS B ON A.PKEbelista=B.PKEbelista
WHERE A.ANIOCAMPANA = A.ANIOCAMPANAREF AND (ANIOCAMPANA BETWEEN @CampanaInicioCosecha AND @CampanaExito) 

IF OBJECT_ID ('TEMPDB..#ESTRUCTURAFINAL') IS NOT NULL DROP TABLE #ESTRUCTURAFINAL
; WITH PRE_NEXITO 
AS
(
SELECT A.PKEBELISTA, A.CODEBELISTA, B.DesNivelComportamiento, A.FlagActiva, 
max(Edad) Edad
FROM #FSTAEBECAMC01 A
INNER JOIN DCOMPORTAMIENTOROLLING B ON A.CodComportamientoRolling=B.CodComportamiento
WHERE A.AnioCampana=@CampanaExito
GROUP BY A.PKEBELISTA, A.CODEBELISTA, B.DesNivelComportamiento, A.FlagActiva
), 
NEXITO AS
(
SELECT A.PKEBELISTA,A.CODEBELISTA,A.DesNivelComportamiento,A.FlagActiva,Edad,
SUM(CASE WHEN RealVtaMNNeto>0 THEN isnull(RealUUVendidas,0) END) UUVendidasC7, 
SUM(isnull(RealVtaMNNeto,0) ) VtaMNNetoC7
FROM PRE_NEXITO A
LEFT JOIN #FVTAPROEBECAMC01 C ON A.PKEbelista=C.PKEbelista 
GROUP BY A.PKEBELISTA,A.CODEBELISTA,A.DesNivelComportamiento,A.FlagActiva,Edad
)
	SELECT @CampanaInicioCosecha AS CAMPINICIO, 
	A.AnioCampana AS ANIOCAMPANAPROCESO,
	@CampanaFinCosecha AS CAMPFIN, 
	@CampanaExito AS CAMPEXITO,
	A.PKEBELISTA, A.CODEBELISTA,
	CASE WHEN LEFT(CONSTANCIA,1) ='I' THEN 0 ELSE 1 END FLAGCONSTANCIA,
	SUBSTRING(CONSTANCIA,3,1) AS NROPEDIDOS,
	sum(case when (A.FlagIPUnicoZona is null or A.FlagIPUnicoZona=0) then 0 else 1 end) over (partition by A.pkebelista order by A.aniocampana) AS IPUnicoAc,
	sum(case when (A.FlagPasoPedido=1 and A.codigofacturainternet in ('WEB','WMX')) then 1 else 0 end) over (partition by A.pkebelista order by A.aniocampana) as PedidosWebAc,
	sum(case when F.NroIngresosWeb is null then 0 else F.NroIngresosWeb end) over (partition by A.pkebelista order by A.aniocampana) AS NumLogueosAc,
	sum(isnull(G.numpalancas,0)) over (partition by A.pkebelista order by A.aniocampana) AS NumPalancasAc,
	RIGHT(CONSTANCIA,1) AS NROCAMPVENTA,
	C.DESNIVELCOMPORTAMIENTO AS EXITOC7,
	C.FlagActiva AS FLAGACTIVAC7,
	isnull(VtaMNNetoC7,0) AS VtaMNNetoC7,
	isnull(UUVendidasC7,0) AS UUVendidasC7,
	A.EDAD,
	D.CodRegion,
	D.DesRegion,
	D.CodZona,
	d.CodLider,
	E.DESNIVEL,E.RENDIMIENTOCAMPANA,E.RENDIMIENTOETAPA,
	-- Agregando la columna del numero de veces que acompaña un nivel de socia (pre-bronce,bronce,etc) a una consultora, y lo mismo para rendcampana y rend etapa
	SUM(1) OVER(partition by A.pkebelista, E.DESNIVEL order by A.aniocampana) as NumVecesNivelSocia,
	SUM(1) OVER(partition by A.pkebelista, E.RENDIMIENTOCAMPANA order by A.aniocampana) as NumVecesRendCampSocia,
	SUM(1) OVER(partition by A.pkebelista, E.RENDIMIENTOETAPA order by A.aniocampana) as NumVecesRendEtSocia
	INTO #ESTRUCTURAFINAL
	FROM #FSTAEBECAMC01 A
	INNER JOIN DGEOGRAFIACAMPANA D ON A.PKTerritorio=D.PKTerritorio AND A.AnioCampana=D.AnioCampana
	LEFT JOIN DATAMARTCOMCORP.DBO.BDLideres_Base_Paises E ON E.CODLIDER=D.CODLIDER AND A.ANIOCAMPANA = E.ANIOCAMPANA AND E.CodPais = 'CH'
	LEFT JOIN NEXITO C ON A.PKEBELISTA=C.PKEBELISTA
	LEFT JOIN FSTAEBECAMWEB  F ON A.PKEBELISTA=F.pkebelista and A.aniocampana=F.aniocampanaweb
	LEFT JOIN #CONTEOPALANCAS  G ON A.PKEBELISTA=G.pkebelista and A.aniocampana=G.aniocampana
	WHERE A.ANIOCAMPANA BETWEEN @CampanaInicioCosecha AND @CampanaFinCosecha

-- SOCIA Y EXITO

IF OBJECT_ID ('TEMPDB..#LIDERES') IS NOT NULL DROP TABLE #LIDERES
; WITH LIDERES AS
(
SELECT B.CodLider
FROM #FSTAEBECAMC01 A
INNER JOIN DGEOGRAFIACAMPANA B ON A.PKTerritorio=B.PKTerritorio AND A.AnioCampana=B.AnioCampana
WHERE A.AnioCampana BETWEEN @CampanaInicioCosecha AND @CampanaFinCosecha
GROUP BY B.CodLider
)
SELECT C.CodLider,
COUNT(DISTINCT CASE WHEN A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 THEN B.ANIOCAMPANA ELSE NULL END) VIDASOCIA6,
COUNT(DISTINCT CASE WHEN A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 THEN PKEbelista ELSE NULL END) NROCONSULTORAS, 
COUNT(DISTINCT CASE WHEN A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 AND (A.CodComportamientoRolling=1 OR A.codstatus=1) THEN PKEbelista ELSE NULL END) NRONUEVAS, 
COUNT(DISTINCT CASE WHEN A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 AND CodStatus=1 THEN PKEBELISTA ELSE NULL END) NROINGRESOS,
COUNT(DISTINCT CASE WHEN A.FlagActiva=1 AND A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 THEN PKEbelista ELSE NULL END) NROCONSULTORAS_ACT,
CASE WHEN (COUNT(CASE WHEN A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 AND (A.CodComportamientoRolling=1 OR A.codstatus=1) THEN PKEBELISTA ELSE NULL END))>0
THEN COUNT(CASE WHEN A.FlagActiva=1 AND A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 AND (A.CodComportamientoRolling=1 OR A.codstatus=1) THEN PKEBELISTA ELSE NULL END)/
	(COUNT(CASE WHEN A.ANIOCAMPANA BETWEEN @INICIOMenos6 AND @INICIOMenos1 AND (A.CodComportamientoRolling=1 OR A.codstatus=1) THEN PKEBELISTA ELSE NULL END)*1.0) 
ELSE 0 END AS RTNUEVAS_ACT,
COUNT(DISTINCT CASE WHEN A.flagexito=1 THEN PKEbelista else null end )as NROINGRESOS_EXITOSAS
INTO #LIDERES
FROM #FSTAEBECAMC01_2 A
INNER JOIN DGEOGRAFIACAMPANA B ON A.AnioCampana=B.AnioCampana AND A.PKTerritorio=B.PKTerritorio
RIGHT JOIN LIDERES C ON B.CodLider=C.CodLider
GROUP BY C.CodLider

---------------------------
-- 1. MARCAS Y CATEGORÍA --
---------------------------

if object_id ('tempdb..#ConteoMyC') is not null drop table #ConteoMyC
select	f.CAMPINICIO,f.ANIOCAMPANAPROCESO,f.CAMPFIN,f.CAMPEXITO,f.PKEBELISTA,f.CODEBELISTA,
		e.CodMarca,
		case when e.DesClase = 'CUIDADO PERSONAL' then 'CP'
		when e.DesClase = 'FRAGANCIAS' then 'FG'
		when e.DesClase = 'MAQUILLAJE' then 'MQ'
		when e.DesClase = 'TRATAMIENTO CORPORAL' then 'TC'
		when e.DesClase = 'TRATAMIENTO FACIAL' then 'TF' end CodCategoria,
		count(distinct a.AnioCampana) NROPEDIDOS,
		sum(a.RealVtaMNNeto/RealTCPromedio) as RealVtaMENeto,
		sum(a.RealUUVendidas) as RealUUVendidas,
		sum(a.RealUUVendidas)/(count(distinct a.AnioCampana)*1.0) as PUP
into #ConteoMyC
from #FVTAPROEBECAMC01 a
inner join #ESTRUCTURAFINAL f on a.PKEbelista=f.PKEbelista and a.AnioCampana<=f.ANIOCAMPANAPROCESO
inner join dproducto e on a.PkProducto=e.PkProducto
where a.AnioCampana=a.AnioCampanaRef and a.AnioCampana between @CampanaInicioCosecha and F.ANIOCAMPANAPROCESO
and e.CodMarca in ('A','B','C')
and e.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') 
and a.PKTipoOferta in (
	select PKTipoOferta from dtipooferta 
	where CodTipoProfit='01')
and a.CodVenta in (select CodVenta from DMATRIZCAMPANA where CodVenta <> '00000' and AnioCampana between @CampanaInicioCosecha and F.ANIOCAMPANAPROCESO)
group by f.CAMPINICIO,f.ANIOCAMPANAPROCESO,f.CAMPFIN,f.CAMPEXITO,f.PKEBELISTA,f.CODEBELISTA,
		e.CodMarca, e.DesClase
having sum(a.RealUUVendidas)>0 AND SUM(A.REALVTAMNNETO)>0


if object_id ('tempdb..#MyC_PUP') is not null drop table #MyC_PUP
create table #MyC_PUP
(CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
PKEbelista int, CodEbelista varchar(15),
Pc_Lb_Cp decimal(12,4), Pc_Lb_Fg decimal(12,4), Pc_Lb_Mq decimal(12,4), Pc_Lb_Tc decimal(12,4), Pc_Lb_Tf decimal(12,4),
Pc_Ek_Cp decimal(12,4), Pc_Ek_Fg decimal(12,4), Pc_Ek_Mq decimal(12,4), Pc_Ek_Tc decimal(12,4), Pc_Ek_Tf decimal(12,4),
Pc_Cz_Cp decimal(12,4), Pc_Cz_Fg decimal(12,4), Pc_Cz_Mq decimal(12,4), Pc_Cz_Tc decimal(12,4), Pc_Cz_Tf decimal(12,4))

if object_id ('tempdb..#MyC_P$P') is not null drop table #MyC_P$P
create table #MyC_P$P
(CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
PKEbelista int, CodEbelista varchar(15),
P$P_Lb_Cp decimal(12,2), P$P_Lb_Fg decimal(12,2), P$P_Lb_Mq decimal(12,2), P$P_Lb_Tc decimal(12,2), P$P_Lb_Tf decimal(12,2),
P$P_Ek_Cp decimal(12,2), P$P_Ek_Fg decimal(12,2), P$P_Ek_Mq decimal(12,2), P$P_Ek_Tc decimal(12,2), P$P_Ek_Tf decimal(12,2),
P$P_Cz_Cp decimal(12,2), P$P_Cz_Fg decimal(12,2), P$P_Cz_Mq decimal(12,2), P$P_Cz_Tc decimal(12,2), P$P_Cz_Tf decimal(12,2))


insert into #MyC_PUP
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, 
	isnull([Lb_Cp1],0) as Pc_Lb_Cp_PUP,isnull([Lb_Fg1],0) as Pc_Lb_Fg_PUP,isnull([Lb_Mq1],0) as Pc_Lb_Mq_PUP,isnull([Lb_Tc1],0) as Pc_Lb_Tc_PUP,isnull([Lb_Tf1],0) as Pc_Lb_Tf_PUP,
	isnull([Ek_Cp1],0) as Pc_Ek_Cp_PUP,isnull([Ek_Fg1],0) as Pc_Ek_Fg_PUP,isnull([Ek_Mq1],0) as Pc_Ek_Mq_PUP,isnull([Ek_Tc1],0) as Pc_Ek_Tc_PUP,isnull([Ek_Tf1],0) as Pc_Ek_Tf_PUP,
	isnull([Cz_Cp1],0) as Pc_Cz_Cp_PUP,isnull([Cz_Fg1],0) as Pc_Cz_Fg_PUP,isnull([Cz_Mq1],0) as Pc_Cz_Mq_PUP,isnull([Cz_Tc1],0) as Pc_Cz_Tc_PUP,isnull([Cz_Tf1],0) as Pc_Cz_Tf_PUP
FROM
(SELECT a.CAMPINICIO, a.ANIOCAMPANAPROCESO, a.CAMPFIN, a.CAMPEXITO, a.pkebelista, a.CodEbelista,
		CASE 
			WHEN a.CodMarca='A' and a.CodCategoria='CP' THEN 'Lb_Cp1'
			WHEN a.CodMarca='A' and a.CodCategoria='FG' THEN 'Lb_Fg1'
			WHEN a.CodMarca='A' and a.CodCategoria='MQ' THEN 'Lb_Mq1'
			WHEN a.CodMarca='A' and a.CodCategoria='TC' THEN 'Lb_Tc1'
			WHEN a.CodMarca='A' and a.CodCategoria='TF' THEN 'Lb_Tf1'
			WHEN a.CodMarca='B' and a.CodCategoria='CP' THEN 'Ek_Cp1'
			WHEN a.CodMarca='B' and a.CodCategoria='FG' THEN 'Ek_Fg1'
			WHEN a.CodMarca='B' and a.CodCategoria='MQ' THEN 'Ek_Mq1'
			WHEN a.CodMarca='B' and a.CodCategoria='TC' THEN 'Ek_Tc1'
			WHEN a.CodMarca='B' and a.CodCategoria='TF' THEN 'Ek_Tf1'
			WHEN a.CodMarca='C' and a.CodCategoria='CP' THEN 'Cz_Cp1'
			WHEN a.CodMarca='C' and a.CodCategoria='FG' THEN 'Cz_Fg1'
			WHEN a.CodMarca='C' and a.CodCategoria='MQ' THEN 'Cz_Mq1'
			WHEN a.CodMarca='C' and a.CodCategoria='TC' THEN 'Cz_Tc1'
			WHEN a.CodMarca='C' and a.CodCategoria='TF' THEN 'Cz_Tf1'
		END As CodMC1,
 cast([PUP] as real)/(select SUM(PUP) from #ConteoMyC 
					  where codebelista=a.codebelista and ANIOCAMPANAPROCESO=a.ANIOCAMPANAPROCESO 
					  group by CodEbelista,ANIOCAMPANAPROCESO) as Pc
 FROM #ConteoMyC a) AS SourceTable
PIVOT
(
MAX(Pc)
FOR CodMC1 IN ([Lb_Cp1],[Lb_Fg1],[Lb_Mq1],[Lb_Tc1],[Lb_Tf1],[Ek_Cp1],[Ek_Fg1],[Ek_Mq1],[Ek_Tc1],[Ek_Tf1],[Cz_Cp1],[Cz_Fg1],[Cz_Mq1],[Cz_Tc1],[Cz_Tf1])
) AS PivotTable1 

insert into #MyC_P$P
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista,
	isnull([Lb_Cp2],0) as P$P_Lb_Cp_PUP,isnull([Lb_Fg2],0) as P$P_Lb_Fg_PUP,isnull([Lb_Mq2],0) as P$P_Lb_Mq_PUP,isnull([Lb_Tc2],0) as P$P_Lb_Tc_PUP,isnull([Lb_Tf2],0) as P$P_Lb_Tf_PUP,
	isnull([Ek_Cp2],0) as P$P_Ek_Cp_PUP,isnull([Ek_Fg2],0) as P$P_Ek_Fg_PUP,isnull([Ek_Mq2],0) as P$P_Ek_Mq_PUP,isnull([Ek_Tc2],0) as P$P_Ek_Tc_PUP,isnull([Ek_Tf2],0) as P$P_Ek_Tf_PUP,
	isnull([Cz_Cp2],0) as P$P_Cz_Cp_PUP,isnull([Cz_Fg2],0) as P$P_Cz_Fg_PUP,isnull([Cz_Mq2],0) as P$P_Cz_Mq_PUP,isnull([Cz_Tc2],0) as P$P_Cz_Tc_PUP,isnull([Cz_Tf2],0) as P$P_Cz_Tf_PUP
FROM
(SELECT a.CAMPINICIO, a.ANIOCAMPANAPROCESO, a.CAMPFIN, a.CAMPEXITO, a.pkebelista, a.CodEbelista,
		CASE 
			WHEN a.CodMarca='A' and a.CodCategoria='CP' THEN 'Lb_Cp2'
			WHEN a.CodMarca='A' and a.CodCategoria='FG' THEN 'Lb_Fg2'
			WHEN a.CodMarca='A' and a.CodCategoria='MQ' THEN 'Lb_Mq2'
			WHEN a.CodMarca='A' and a.CodCategoria='TC' THEN 'Lb_Tc2'
			WHEN a.CodMarca='A' and a.CodCategoria='TF' THEN 'Lb_Tf2'
			WHEN a.CodMarca='B' and a.CodCategoria='CP' THEN 'Ek_Cp2'
			WHEN a.CodMarca='B' and a.CodCategoria='FG' THEN 'Ek_Fg2'
			WHEN a.CodMarca='B' and a.CodCategoria='MQ' THEN 'Ek_Mq2'
			WHEN a.CodMarca='B' and a.CodCategoria='TC' THEN 'Ek_Tc2'
			WHEN a.CodMarca='B' and a.CodCategoria='TF' THEN 'Ek_Tf2'
			WHEN a.CodMarca='C' and a.CodCategoria='CP' THEN 'Cz_Cp2'
			WHEN a.CodMarca='C' and a.CodCategoria='FG' THEN 'Cz_Fg2'
			WHEN a.CodMarca='C' and a.CodCategoria='MQ' THEN 'Cz_Mq2'
			WHEN a.CodMarca='C' and a.CodCategoria='TC' THEN 'Cz_Tc2'
			WHEN a.CodMarca='C' and a.CodCategoria='TF' THEN 'Cz_Tf2'
		END As CodMC2,
 RealVtaMENeto/(NROPEDIDOS*1.0) as P$P
 FROM #ConteoMyC a) AS SourceTable 
PIVOT
(
MAX(P$P)
FOR CodMC2 IN ([Lb_Cp2],[Lb_Fg2],[Lb_Mq2],[Lb_Tc2],[Lb_Tf2],[Ek_Cp2],[Ek_Fg2],[Ek_Mq2],[Ek_Tc2],[Ek_Tf2],[Cz_Cp2],[Cz_Fg2],[Cz_Mq2],[Cz_Tc2],[Cz_Tf2])
) AS PivotTable2 
 
---------------------------
-- 2. CATALOGO Y REVISTA --
---------------------------

if object_id ('tempdb..#ConteoCyR') is not null drop table #ConteoCyR
select	f.CAMPINICIO,f.ANIOCAMPANAPROCESO,f.CAMPFIN,f.CAMPEXITO,f.PKEBELISTA,f.CODEBELISTA,
		case 
			when g.vehiculoventa='CATÁLOGO' then 'CAT1' 
			when g.vehiculoventa='REVISTA' then 'REV1' 
			else 'OTROS1' 
		end AS VehiculoVenta1,
		case 
			when g.vehiculoventa='CATÁLOGO' then 'CAT2' 
			when g.vehiculoventa='REVISTA' then 'REV2' 
			else 'OTROS2' 
		end AS VehiculoVenta2,
		count(distinct a.AnioCampana) as NroPedidos,
		sum(a.RealVtaMNNeto/RealTCPromedio) as RealVtaMENeto,
		sum(a.RealUUVendidas) as RealUUVendidas,
		sum(a.RealUUVendidas)/(count(distinct a.AnioCampana)*1.0) as PUP
into #ConteoCyR 
from #FVTAPROEBECAMC01 a
inner join #ESTRUCTURAFINAL f on a.PKEbelista=f.PKEbelista and a.AnioCampana<=f.ANIOCAMPANAPROCESO
inner join dproducto e on a.PkProducto=e.PkProducto
inner join dmatrizcampana g on a.codcanalventa=g.codcanalventa and a.aniocampana =  g.aniocampana and a.pkproducto = g.pkproducto and a.pktipooferta = g.pktipooferta and a.CodVenta=g.codventa
where a.AnioCampana=a.AnioCampanaRef and a.AnioCampana between @CampanaInicioCosecha and F.ANIOCAMPANAPROCESO
and e.CodMarca in ('A','B','C')
and e.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') 
and a.PKTipoOferta in (
	select PKTipoOferta from dtipooferta 
	where CodTipoProfit='01')
and a.CodVenta in (select CodVenta from DMATRIZCAMPANA where CodVenta <> '00000' and AnioCampana between @CampanaInicioCosecha and F.ANIOCAMPANAPROCESO)
group by f.CAMPINICIO,f.ANIOCAMPANAPROCESO,f.CAMPFIN,f.CAMPEXITO,f.PKEBELISTA,f.CODEBELISTA,
		case 
			when g.vehiculoventa='CATÁLOGO' then 'CAT1' 
			when g.vehiculoventa='REVISTA' then 'REV1' 
			else 'OTROS1' 
		end,
		case 
			when g.vehiculoventa='CATÁLOGO' then 'CAT2' 
			when g.vehiculoventa='REVISTA' then 'REV2' 
			else 'OTROS2' 
		end
having sum(a.RealUUVendidas)>0 AND SUM(A.REALVTAMNNETO)>0

--select * FROM #ConteoCyR order by pkebelista, aniocampanaproceso --Para comparar la forma de calcular NROPEDIDOS

if object_id ('tempdb..#FINALCyR_PUP') is not null drop table #FINALCyR_PUP
create table #FINALCyR_PUP (CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
PKEbelista int, CodEbelista varchar(15),
Pc_Catalogo decimal(12,4), Pc_Revista decimal(12,4), Pc_Otros decimal(12,4))

if object_id ('tempdb..#FINALCyR_P$P') is not null drop table #FINALCyR_P$P
create table #FINALCyR_P$P (CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
PKEbelista int, CodEbelista varchar(15),
P$P_Catalogo decimal(12,2), P$P_Revista decimal(12,2), P$P_Otros decimal(12,2))

Insert into #FINALCyR_PUP
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, 
	isnull([CAT1],0) as Pc_Catalogo,isnull([REV1],0) as Pc_Revista,isnull([OTROS1],0) as Pc_Otros
FROM
(SELECT CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, vehiculoventa1, 
		cast([PUP] as real)/(select SUM(PUP) from #ConteoCyR 
					  where codebelista=a.codebelista and ANIOCAMPANAPROCESO=a.ANIOCAMPANAPROCESO 
					  group by CodEbelista, ANIOCAMPANAPROCESO) as PUP
 FROM #ConteoCyR a) AS SourceTable
PIVOT
(
MAX([PUP])
FOR vehiculoventa1 IN ([CAT1],[REV1],[OTROS1])
) AS PivotTable1

Insert into #FINALCyR_P$P
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista,
	isnull([CAT2],0) as P$P_Catalogo,isnull([REV2],0) as P$P_Revista,isnull([OTROS2],0) as P$P_Otros
FROM
(SELECT CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, vehiculoventa2,
		RealVtaMENeto/(NROPEDIDOS*1.0) as P$P
 FROM #ConteoCyR a) AS SourceTable
PIVOT
(
MAX([P$P])
FOR vehiculoventa2 IN ([CAT2],[REV2],[OTROS2])
) AS PivotTable2

--------------
-- 2. TIPOS --
--------------

if object_id ('tempdb..#DPRODUCTO1') is not null drop table #DPRODUCTO1
 select		a.*,	--case when DesUnidadNegocio = 'COSMETICOS' then 'COSMETICOS' else 'NO COSMETICOS' End DesUnidadNegocio2,
					case when DesClase='BIJOUTERIE' then 'BIJOUTERIE' 
					when DesClase='HOGAR' then 'HOGAR'
					WHEN DesClase='LENTES' then 'LENTES'
					WHEN DesClase='RELOJES' then 'RELOJES'
					WHEN DesClase='ROPA' then 'COMPLEMENTOS'
					WHEN DesClase='COMPLEMENTOS' then DesTipoSolo
					WHEN DesClase='PROMOCION USUARIO' and DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' then DesSubTipoSolo
					WHEN DesClase='PROMOCION USUARIO' and DesSubCategoria='PROMOCION USUARIOS HOGAR' then 'HOGAR'
					WHEN DesClase='PROMOCION USUARIO' and DesSubCategoria='VARIOS VARIOS' then DesProducto else 'No Clasificado' End Categoria
 into #DPRODUCTO1
 from DPRODUCTO a


if object_id ('tempdb..#DPRODUCTO2') is not null drop table #DPRODUCTO2
 select		a.*,	case when Categoria='BIJOUTERIE' then 'BIJOUTERIE'
					when Categoria='HOGAR' then 'HOGAR'
					WHEN Categoria='LENTES' then 'LENTES_RELOJ'
					WHEN Categoria='RELOJES' then 'LENTES_RELOJ'
					WHEN Categoria='MALETIN' then 'MALETIN_MOCHILA'
					WHEN Categoria='MOCHILA' then 'MALETIN_MOCHILA'
					WHEN Categoria='CARTERA' then 'CARTERA_BOLSO'
					WHEN Categoria='BOLSO' then 'CARTERA_BOLSO'
					WHEN Categoria='BILLETERA' then 'BILLETERA'
					WHEN Categoria='COMPLEMENTOS' then 'COMPLEMENTOS'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%BILLETERA%' then 'BILLETERA'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%CARTERA/BOLSO%' then 'CARTERA_BOLSO'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%BOLSO%' then 'CARTERA_BOLSO'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%CARTERA%' then 'CARTERA_BOLSO'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%CANGURO%' then 'COMPLEMENTOS'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%CORREA%' then 'COMPLEMENTOS'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%MALETIN%' then 'MALETIN_MOCHILA'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%MOCHILA%' then 'MALETIN_MOCHILA'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%PAÑUELO%' then 'COMPLEMENTOS'
					WHEN DesClase='COMPLEMENTOS' AND Categoria LIKE '%NECESER%' then 'COMPLEMENTOS'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' AND Categoria LIKE '%MOCHILA%' then 'MALETIN_MOCHILA'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' AND Categoria LIKE '%MALETIN%' then 'MALETIN_MOCHILA'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' AND Categoria LIKE '%CARTERA%' then 'CARTERA_BOLSO'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' AND Categoria LIKE '%BILLETERA%' then 'BILLETERA'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' AND Categoria LIKE '%RELOJ%' then 'LENTES_RELOJ'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='PROMOCION USUARIOS COMPLEMENTOS' AND Categoria LIKE '%LENTES%' then 'LENTES_RELOJ'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%LENTES%' then 'LENTES_RELOJ'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%RELOJ%' then 'LENTES_RELOJ'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%CARTERA%' then 'CARTERA_BOLSO'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%BOLSO%' then 'CARTERA_BOLSO'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%BILLETERA%' then 'BILLETERA'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%NECESER%' then 'NECESER'		
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%MOCHILA%' then 'MALETIN_MOCHILA'
					WHEN DesClase='PROMOCION USUARIO' AND DesSubCategoria='VARIOS VARIOS' AND Categoria LIKE '%MALETIN%' then 'MALETIN_MOCHILA' ELSE 'No Clasificado' end Categoria2
 into  #DPRODUCTO2
 from #DPRODUCTO1 a

if object_id ('tempdb..#DPRODUCTO3') is not null drop table #DPRODUCTO3
 select		a.*,	case when Categoria2='BIJOUTERIE' then 'BIJOUTERIE' 
					when Categoria2='HOGAR' then 'HOGAR'
					when Categoria2='LENTES_RELOJ' then 'LENTES_RELOJ'
					when Categoria2='CARTERA_BOLSO' then 'BILLETERA_CARTERA'
					when Categoria2='BILLETERA' then 'BILLETERA_CARTERA'
					when Categoria2='MALETIN_MOCHILA' then 'MALETIN_MOCHILA'
					when Categoria2='NECESER' then 'COMPLEMENTOS'
					when Categoria2='COMPLEMENTOS' then 'COMPLEMENTOS' End T_Categoria
 into #DPRODUCTO3
 from #DPRODUCTO2 a
 where Categoria<>'No Clasificado' AND Categoria2<>'No Clasificado'

-- BD PRINCIPAL AGRUPANDO COSMETICOS Y NO COSMETICOS

if object_id ('tempdb..#BD_COS_Y_NOCOS') is not null drop table #BD_COS_Y_NOCOS
select	d.CAMPINICIO,d.ANIOCAMPANAPROCESO,d.CAMPFIN,d.CAMPEXITO,d.PKEBELISTA,d.CODEBELISTA,
		case when g.T_Categoria in ('LENTES_RELOJ','HOGAR','MALETIN_MOCHILA','BILLETERA_CARTERA','BIJOUTERIE','COMPLEMENTOS')
			   and e.DesUnidadNegocio<>'COSMETICOS' and e.CodUnidadNegocio<>'01' then 'NO_COSMETICOS1' 
			 when e.CodMarca in ('A','B','C')
				and e.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') then 'COSMETICOS1' 
			 else 'NO_CLASIFICADO1'
		End CodClasificacion1,
		case when g.T_Categoria in ('LENTES_RELOJ','HOGAR','MALETIN_MOCHILA','BILLETERA_CARTERA','BIJOUTERIE','COMPLEMENTOS')
			   and e.DesUnidadNegocio<>'COSMETICOS' and e.CodUnidadNegocio<>'01' then 'NO_COSMETICOS2' 
			 when e.CodMarca in ('A','B','C')
				and e.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') then 'COSMETICOS2' 
			 else 'NO_CLASIFICADO2'
		End CodClasificacion2,
		count(distinct a.AnioCampana) NROPEDIDOS,
		sum(a.RealVtaMNNeto/RealTCPromedio) as RealVtaMENeto,
		sum(a.RealUUVendidas) as RealUUVendidas,
		sum(a.RealUUVendidas)/(count(distinct a.AnioCampana)*1.0) as PUP
into #BD_COS_Y_NOCOS
from FVTAPROEBECAMC01 a
inner join #ESTRUCTURAFINAL d on a.PKEbelista=d.PKEbelista and a.AnioCampana<=d.ANIOCAMPANAPROCESO
inner join dproducto e on a.PkProducto=e.PkProducto
left join (select pkproducto, T_Categoria from #DPRODUCTO3) g on a.PkProducto=g.PkProducto
inner join DTIPOOFERTA f on a.PKTipoOferta=f.PKTipoOferta
where a.AnioCampana=a.AnioCampanaRef and a.AnioCampana between @CampanaInicioCosecha and d.ANIOCAMPANAPROCESO
and A.realvtamnneto>0 and f.CodTipoProfit='01'
and a.CodVenta in (select CodVenta from DMATRIZCAMPANA where CodVenta <> '00000' and AnioCampana between @CampanaInicioCosecha and d.ANIOCAMPANAPROCESO)
group by d.CAMPINICIO,d.ANIOCAMPANAPROCESO,d.CAMPFIN,d.CAMPEXITO,d.PKEBELISTA,d.CODEBELISTA,
		case when g.T_Categoria in ('LENTES_RELOJ','HOGAR','MALETIN_MOCHILA','BILLETERA_CARTERA','BIJOUTERIE','COMPLEMENTOS')
			   and e.DesUnidadNegocio<>'COSMETICOS' and e.CodUnidadNegocio<>'01' then 'NO_COSMETICOS1' 
			 when e.CodMarca in ('A','B','C')
				and e.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') then 'COSMETICOS1' 
			 else 'NO_CLASIFICADO1'
		End,
		case when g.T_Categoria in ('LENTES_RELOJ','HOGAR','MALETIN_MOCHILA','BILLETERA_CARTERA','BIJOUTERIE','COMPLEMENTOS')
			   and e.DesUnidadNegocio<>'COSMETICOS' and e.CodUnidadNegocio<>'01' then 'NO_COSMETICOS2' 
			 when e.CodMarca in ('A','B','C')
				and e.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') then 'COSMETICOS2' 
			 else 'NO_CLASIFICADO2'
		End
having sum(a.RealUUVendidas)>0

if object_id ('tempdb..#PIVOTBD_PUP') is not null drop table #PIVOTBD_PUP
create table #PIVOTBD_PUP (CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
PKEbelista int, CodEbelista varchar(15),
Pc_Cosmeticos decimal(12,4), Pc_NoCosmeticos decimal(12,4), Pc_NoClasificado decimal(12,4))

if object_id ('tempdb..#PIVOTBD_P$P') is not null drop table #PIVOTBD_P$P
create table #PIVOTBD_P$P (CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
PKEbelista int, CodEbelista varchar(15),
P$P_Cosmeticos decimal(12,2), P$P_NoCosmeticos decimal(12,2), P$P_NoClasificado decimal(12,2))

Insert into #PIVOTBD_PUP
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, 
	isnull([COSMETICOS1],0) as Pc_Cosmeticos,isnull([NO_COSMETICOS1],0) as Pc_NoCosmeticos,isnull([NO_CLASIFICADO1],0) as Pc_NoClasificado
FROM
(SELECT CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, CodClasificacion1,
		cast([PUP] as real)/(select SUM(PUP) from #BD_COS_Y_NOCOS
					  where codebelista=a.codebelista and ANIOCAMPANAPROCESO=a.ANIOCAMPANAPROCESO 
					  group by CodEbelista,ANIOCAMPANAPROCESO) as PUP
 FROM #BD_COS_Y_NOCOS a) AS SourceTable
PIVOT
(
MAX([PUP])
FOR CodClasificacion1 IN ([COSMETICOS1],[NO_COSMETICOS1],[NO_CLASIFICADO1])
) AS PivotTable1

Insert into #PIVOTBD_P$P
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista,
	isnull([COSMETICOS2],0) as P$P_Cosmeticos,isnull([NO_COSMETICOS2],0) as P$P_NoCosmeticos,isnull([NO_CLASIFICADO2],0) as P$P_NoClasificado
FROM
(SELECT CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, CodClasificacion2,
		RealVtaMENeto/(NROPEDIDOS*1.0) as P$P
 FROM #BD_COS_Y_NOCOS a) AS SourceTable
PIVOT
(
MAX([P$P])
FOR CodClasificacion2 IN ([COSMETICOS2],[NO_COSMETICOS2],[NO_CLASIFICADO2])
) AS PivotTable2


-- NO COSMETICOS 

if object_id ('tempdb..#ConteoCategorias') is not null drop table #ConteoCategorias
select	d.CAMPINICIO,d.ANIOCAMPANAPROCESO,d.CAMPFIN,d.CAMPEXITO,d.PKEBELISTA,d.CODEBELISTA,
		e.T_Categoria,
		case when e.T_Categoria = 'LENTES_RELOJ' then 'RLJ_LNT1'
		when e.T_Categoria = 'HOGAR' then 'HG1'
		when e.T_Categoria = 'MALETIN_MOCHILA' then 'MLT_MOCH1'
		when e.T_Categoria = 'BILLETERA_CARTERA' then 'BILLT_CART1'
		when e.T_Categoria = 'BIJOUTERIE' then 'BJT1'
		when e.T_Categoria = 'COMPLEMENTOS' then 'COMPL1' End CodCategoria1,
		case when e.T_Categoria = 'LENTES_RELOJ' then 'RLJ_LNT2'
		when e.T_Categoria = 'HOGAR' then 'HG2'
		when e.T_Categoria = 'MALETIN_MOCHILA' then 'MLT_MOCH2'
		when e.T_Categoria = 'BILLETERA_CARTERA' then 'BILLT_CART2'
		when e.T_Categoria = 'BIJOUTERIE' then 'BJT2'
		when e.T_Categoria = 'COMPLEMENTOS' then 'COMPL2' End CodCategoria2,
		count(distinct a.AnioCampana) NROPEDIDOS,
		sum(a.RealVtaMNNeto/RealTCPromedio) as RealVtaMENeto,
		sum(a.RealUUVendidas) as RealUUVendidas,
		sum(a.RealUUVendidas)/(count(distinct a.AnioCampana)*1.0) as PUP
into #ConteoCategorias
from FVTAPROEBECAMC01 a
inner join #ESTRUCTURAFINAL d on a.PKEbelista=d.PKEbelista and a.AnioCampana<=d.ANIOCAMPANAPROCESO
inner join #DPRODUCTO3 e on a.PkProducto=e.PkProducto
inner join DTIPOOFERTA f on a.PKTipoOferta=f.PKTipoOferta
where a.AnioCampana=a.AnioCampanaRef and a.AnioCampana between @CampanaInicioCosecha and d.ANIOCAMPANAPROCESO
and e.T_Categoria in ('LENTES_RELOJ','HOGAR','MALETIN_MOCHILA','BILLETERA_CARTERA','BIJOUTERIE','COMPLEMENTOS') 
and e.DesUnidadNegocio<>'COSMETICOS' and f.CodTipoProfit='01' and e.CodUnidadNegocio<>'01' and A.realvtamnneto>0
group by d.CAMPINICIO,d.ANIOCAMPANAPROCESO,d.CAMPFIN,d.CAMPEXITO,d.PKEBELISTA,d.CODEBELISTA,
		e.T_Categoria, 
		case when e.T_Categoria = 'LENTES_RELOJ' then 'RLJ_LNT1'
		when e.T_Categoria = 'HOGAR' then 'HG1'
		when e.T_Categoria = 'MALETIN_MOCHILA' then 'MLT_MOCH1'
		when e.T_Categoria = 'BILLETERA_CARTERA' then 'BILLT_CART1'
		when e.T_Categoria = 'BIJOUTERIE' then 'BJT1'
		when e.T_Categoria = 'COMPLEMENTOS' then 'COMPL1' End,
		case when e.T_Categoria = 'LENTES_RELOJ' then 'RLJ_LNT2'
		when e.T_Categoria = 'HOGAR' then 'HG2'
		when e.T_Categoria = 'MALETIN_MOCHILA' then 'MLT_MOCH2'
		when e.T_Categoria = 'BILLETERA_CARTERA' then 'BILLT_CART2'
		when e.T_Categoria = 'BIJOUTERIE' then 'BJT2'
		when e.T_Categoria = 'COMPLEMENTOS' then 'COMPL2' End
having sum(a.RealUUVendidas)>0

if object_id ('tempdb..#tempoCategoria_PUP') is not null drop table #tempoCategoria_PUP
create table #tempoCategoria_PUP ( CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
							PKEbelista int, CodEbelista varchar(15), 
							Pc_RLJ_LNT decimal(12,4), Pc_HG decimal(12,4), Pc_MLT_MOCH decimal(12,4), Pc_BILLT_CART decimal(12,4), Pc_BJT decimal(12,4), Pc_COMPL decimal(12,4))

if object_id ('tempdb..#tempoCategoria_P$P') is not null drop table #tempoCategoria_P$P
create table #tempoCategoria_P$P ( CAMPINICIO	char(6), ANIOCAMPANAPROCESO	char(6), CAMPFIN	char(6), CAMPEXITO	char(6), 
							PKEbelista int, CodEbelista varchar(15),
							P$P_RLJ_LNT decimal(12,2), P$P_HG decimal(12,2), P$P_MLT_MOCH decimal(12,2), P$P_BILLT_CART decimal(12,2), P$P_BJT decimal(12,2), P$P_COMPL decimal(12,2))


insert into #tempoCategoria_PUP
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, 
	isnull([RLJ_LNT1],0) as Pc_RLJ_LNT,
	isnull([HG1],0) as Pc_HG,
	isnull([MLT_MOCH1],0) as Pc_MLT_MOCH,
	isnull([BILLT_CART1],0) as Pc_BILLT_CART,
	isnull([BJT1],0) as Pc_BJT,
	isnull([COMPL1],0) as Pc_COMPL
FROM
(SELECT CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, CodCategoria1,
		cast([PUP] as real)/(select SUM(PUP) from #ConteoCategorias 
								  where codebelista=a.codebelista and ANIOCAMPANAPROCESO=a.ANIOCAMPANAPROCESO 
								  group by CodEbelista,ANIOCAMPANAPROCESO) as PUP
    FROM #ConteoCategorias a) AS SourceTable
PIVOT
(
AVG([PUP])
FOR CodCategoria1 IN ([RLJ_LNT1],[HG1],[MLT_MOCH1],[BILLT_CART1],[BJT1],[COMPL1])
) AS PivotTable1

insert into #tempoCategoria_P$P
SELECT 
	CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista,
	isnull([RLJ_LNT2],0) as P$P_RLJ_LNT,
	isnull([HG2],0) as P$P_HG,
	isnull([MLT_MOCH2],0) as P$P_MLT_MOCH,
	isnull([BILLT_CART2],0) as P$P_BILLT_CART,
	isnull([BJT2],0) as P$P_BJT,
	isnull([COMPL2],0) as P$P_COMPL
FROM
(SELECT CAMPINICIO, ANIOCAMPANAPROCESO, CAMPFIN, CAMPEXITO, pkebelista, CodEbelista, CodCategoria2,
		RealVtaMENeto/(NROPEDIDOS*1.0) as P$P
    FROM #ConteoCategorias a) AS SourceTable
PIVOT
(
AVG([P$P])
FOR CodCategoria2 IN ([RLJ_LNT2],[HG2],[MLT_MOCH2],[BILLT_CART2],[BJT2],[COMPL2])
) AS PivotTable2


-- COSMETICOS
/*
select top 2 * from DPRODUCTO
select top 2 * from FVTAPROEBECAMC01

Declare @CampanaExito char(6)
Declare @CampanaFinCosecha char(6)
Declare @CampanaInicioCosecha char(6)

Set @CampanaExito = '201718';
Set @CampanaFinCosecha = dbo.CalculaAnioCampana(@CampanaExito, -1)
Set @CampanaInicioCosecha = dbo.CalculaAnioCampana(@CampanaFinCosecha, -5)

--------------
-- obs: hay asimetría
if object_id ('tempdb..#TEMPCOSMETICOS') is not null drop table #TEMPCOSMETICOS
select b.dessubcategoria, LOG(sum(a.realvtamnneto)) AS VentaPorLinea, LOG(count(a.pkebelista)) AS NumConsultoras
into #TEMPCOSMETICOS
from #FVTAPROEBECAMC01 a
inner join DPRODUCTO b on a.pkproducto = b.pkproducto 
inner join DTIPOOFERTA f on a.PKTipoOferta=f.PKTipoOferta
where b.desunidadnegocio = 'COSMETICOS' and f.CodTipoProfit='01' and b.CodUnidadNegocio='01' and a.realvtamnneto>0
	 and b.CodMarca in ('A','B','C')
	 and b.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') 
	 and a.PKTipoOferta in (select PKTipoOferta from dtipooferta 
							where CodTipoProfit='01')
	and a.CodVenta in (select CodVenta from DMATRIZCAMPANA where CodVenta <> '00000' and AnioCampana between @CampanaInicioCosecha and @CampanaFinCosecha)
group by b.dessubcategoria
having sum(a.RealUUVendidas)>0 AND SUM(A.REALVTAMNNETO)>0

select * from #TEMPCOSMETICOS

if object_id ('tempdb..#RANK1') is not null drop table #RANK1
select a.dessubcategoria, (a.VentaPorLinea-(select AVG(VentaPorLinea) from #TEMPCOSMETICOS))/(select STDEV(VentaPorLinea) from #TEMPCOSMETICOS) AS EstVenta, 
		(a.NumConsultoras-(select AVG(NumConsultoras) from #TEMPCOSMETICOS))/(select STDEV(NumConsultoras) from #TEMPCOSMETICOS) AS EstNumConsultoras
into #RANK1
from #TEMPCOSMETICOS a
group by a.dessubcategoria, a.VentaPorLinea, a.NumConsultoras

select dessubcategoria, EstVenta, EstNumConsultoras, (EstVenta + EstNumConsultoras) AS suma
FROM #RANK1
order by 4 desc

--------------------

if object_id ('tempdb..#TEMPCOSMETICOS') is not null drop table #TEMPCOSMETICOS
select b.destiposolo, sum(a.realvtamnneto) AS VentaPorLinea, count(a.pkebelista) AS NumConsultoras
into #TEMPCOSMETICOS
from #FVTAPROEBECAMC01 a
inner join DPRODUCTO b on a.pkproducto = b.pkproducto 
inner join DTIPOOFERTA f on a.PKTipoOferta=f.PKTipoOferta
where b.desunidadnegocio = 'COSMETICOS' and f.CodTipoProfit='01' and b.CodUnidadNegocio='01' and a.realvtamnneto>0
	 and b.CodMarca in ('A','B','C')
	 and b.DesClase in ('CUIDADO PERSONAL','FRAGANCIAS','MAQUILLAJE','TRATAMIENTO CORPORAL','TRATAMIENTO FACIAL') 
	 and a.PKTipoOferta in (select PKTipoOferta from dtipooferta 
							where CodTipoProfit='01')
	and a.CodVenta in (select CodVenta from DMATRIZCAMPANA where CodVenta <> '00000' and AnioCampana between @CampanaInicioCosecha and @CampanaFinCosecha)
group by b.destiposolo
having sum(a.RealUUVendidas)>0 AND SUM(A.REALVTAMNNETO)>0

if object_id ('tempdb..#RANK1') is not null drop table #RANK1
select a.destiposolo, (a.VentaPorLinea-(select AVG(VentaPorLinea) from #TEMPCOSMETICOS))/(select STDEV(VentaPorLinea) from #TEMPCOSMETICOS) AS EstVenta, 
		(a.NumConsultoras-(select AVG(NumConsultoras) from #TEMPCOSMETICOS))/(select STDEV(NumConsultoras) from #TEMPCOSMETICOS) AS EstNumConsultoras
into #RANK1
from #TEMPCOSMETICOS a
group by a.destiposolo, a.VentaPorLinea, a.NumConsultoras

select destiposolo, (EstVenta + EstNumConsultoras) AS suma
FROM #RANK1
order by 2 desc

select * from dproducto where deslinea='ESIKA'

select distinct codunidadnegocio, desunidadnegocio from dproducto
*/

------------ SegmentoC7 TPP -------------------

if object_id ('tempdb..#SegmentoC7') is not null drop table #SegmentoC7
Select 
@CampanaInicioCosecha as CampanaInicioCosecha,
@CampanaFinCosecha as CampanaFinCosecha,
@CampanaExito as CampanaExito,
a.pkebelista,
c.desnivelcomportamiento as SegmentoC7,
flagAV_1 as TPPC6,
flagAV_2 as TPPC5,
flagAV_3 as TPPC4
into #SegmentoC7
from #CONSULTORAS a
inner join fstaebecamc01 b on a.pkebelista=b.pkebelista
inner join dcomportamientorolling c on c.codcomportamiento=b.codcomportamientorolling
left join FINDEBECAMC01_VIEW d on a.pkebelista=d.pkebelista and b.aniocampana=d.aniocampana -- si paso o no el tipping point
where b.aniocampana=@CampanaExito

---- FLAGEO DE CAMPAÑAS BY MH ft. CdA

if object_id ('tempdb..#DetallePedidoCN') is not null Drop table #DetallePedidoCN
; with C2 as 
(
Select a.PKEbelista, 1 as FlagC1, FlagPasoPedido as FlagC2
from fstaebecamc01 a
inner join #CONSULTORAS b on a.pkebelista=b.pkebelista and a.aniocampana=@CampanaInicioCosechaMas1
), C3 as 
(
Select b.*, FlagPasoPedido as FlagC3
from fstaebecamc01 a
inner join C2 b on a.pkebelista=b.pkebelista and a.aniocampana=@CampanaInicioCosechaMas2
), C4 as 
(
Select b.*, FlagPasoPedido as FlagC4
from fstaebecamc01 a
inner join C3 b on a.pkebelista=b.pkebelista and a.aniocampana=@CampanaInicioCosechaMas3
), C5 as 
(
Select b.*, FlagPasoPedido as FlagC5
from fstaebecamc01 a
inner join C4 b on a.pkebelista=b.pkebelista and a.aniocampana=@CampanaInicioCosechaMas4
) 
Select b.*, FlagPasoPedido as FlagC6
into #DetallePedidoCN
from fstaebecamc01 a
inner join C5 b on a.pkebelista=b.pkebelista and a.aniocampana=@CampanaInicioCosechaMas5


----- CONSOLIDANDO
if object_id ('tempdb..#CONSOLIDADO_MH') is not null DROP TABLE #CONSOLIDADO_MH
SELECT A.*,isnull(TPPC6,0) AS TPPC6,isnull(TPPC5,0) AS TPPC5,isnull(TPPC4,0) AS TPPC4,
isnull(VIDASOCIA6,0) AS VIDASOCIA6,isnull(NROCONSULTORAS,0) AS NROCONSULTORAS, isnull(NRONUEVAS,0) AS NRONUEVAS,
isnull(NROINGRESOS,0) AS NROINGRESOS,
isnull(NROCONSULTORAS_ACT,0) AS NROCONSULTORAS_ACT,
round(isnull(RTNUEVAS_ACT,0),4) AS RTNUEVAS_ACT,
isnull(NROINGRESOS_EXITOSAS,0) AS NROINGRESOS_EXITOSAS,
isnull(Pc_Lb_Cp,0) AS Pc_Lb_Cp,
isnull(Pc_Ek_Cp,0) AS Pc_Ek_Cp,
isnull(Pc_Cz_Cp,0) AS Pc_Cz_Cp,
isnull(Pc_Lb_Fg,0) AS Pc_Lb_Fg,
isnull(Pc_Ek_Fg,0) AS Pc_Ek_Fg,
isnull(Pc_Cz_Fg,0) AS Pc_Cz_Fg,
isnull(Pc_Lb_Mq,0) AS Pc_Lb_Mq,
isnull(Pc_Ek_Mq,0) AS Pc_Ek_Mq,
isnull(Pc_Cz_Mq,0) AS Pc_Cz_Mq,
isnull(Pc_Lb_Tc,0) AS Pc_Lb_Tc,
isnull(Pc_Ek_Tc,0) AS Pc_Ek_Tc,
isnull(Pc_Cz_Tc,0) AS Pc_Cz_Tc,
isnull(Pc_Lb_Tf,0) AS Pc_Lb_Tf,
isnull(Pc_Ek_Tf,0) AS Pc_Ek_Tf,
isnull(Pc_Cz_Tf,0) AS Pc_Cz_Tf,
isnull(P$P_Lb_Cp,0) AS P$P_Lb_Cp,
isnull(P$P_Ek_Cp,0) AS P$P_Ek_Cp,
isnull(P$P_Cz_Cp,0) AS P$P_Cz_Cp,
isnull(P$P_Lb_Fg,0) AS P$P_Lb_Fg,
isnull(P$P_Ek_Fg,0) AS P$P_Ek_Fg,
isnull(P$P_Cz_Fg,0) AS P$P_Cz_Fg,
isnull(P$P_Lb_Mq,0) AS P$P_Lb_Mq,
isnull(P$P_Ek_Mq,0) AS P$P_Ek_Mq,
isnull(P$P_Cz_Mq,0) AS P$P_Cz_Mq,
isnull(P$P_Lb_Tc,0) AS P$P_Lb_Tc,
isnull(P$P_Ek_Tc,0) AS P$P_Ek_Tc,
isnull(P$P_Cz_Tc,0) AS P$P_Cz_Tc,
isnull(P$P_Lb_Tf,0) AS P$P_Lb_Tf,
isnull(P$P_Ek_Tf,0) AS P$P_Ek_Tf,
isnull(P$P_Cz_Tf,0) AS P$P_Cz_Tf,
isnull(Pc_Catalogo,0) AS Pc_Catalogo,
isnull(Pc_Revista,0) AS Pc_Revista,
isnull(Pc_Otros,0) AS Pc_Otros,
isnull(P$P_Catalogo,0) AS P$P_Catalogo,
isnull(P$P_Revista,0) AS P$P_Revista,
isnull(P$P_Otros,0) AS P$P_Otros,
isnull(Pc_RLJ_LNT,0) AS Pc_RLJ_LNT,
isnull(Pc_HG,0) AS Pc_HG,
isnull(Pc_MLT_MOCH,0) AS Pc_MLT_MOCH,
isnull(Pc_BILLT_CART,0) AS Pc_BILLT_CART,
isnull(Pc_BJT,0) AS Pc_BJT,
isnull(Pc_COMPL,0) AS Pc_COMPL,
isnull(P$P_RLJ_LNT,0) AS P$P_RLJ_LNT,
isnull(P$P_HG,0) AS P$P_HG,
isnull(P$P_MLT_MOCH,0) AS P$P_MLT_MOCH,
isnull(P$P_BILLT_CART,0) AS P$P_BILLT_CART,
isnull(P$P_BJT,0) AS P$P_BJT,
isnull(P$P_COMPL,0) AS P$P_COMPL,
isnull(Pc_Cosmeticos,0) AS Pc_Cosmeticos,
isnull(Pc_NoCosmeticos,0) AS Pc_NoCosmeticos,
isnull(Pc_NoClasificado,0) AS Pc_NoClasificado,
isnull(P$P_Cosmeticos,0) AS P$P_Cosmeticos,
isnull(P$P_NoCosmeticos,0) AS P$P_NoCosmeticos,
isnull(P$P_NoClasificado,0) AS P$P_NoClasificado,
case when isnull(TPPC6,0) + isnull(TPPC5,0) + isnull(TPPC4,0)=0 and EXITOC7='Inconstantes' then 0
when EXITOC7 in('Constantes 2','Constantes 1','Tops','Brilla') then 1
else -1 end as Target_MH,
isnull(FlagC1,0) AS FlagC1,isnull(FlagC2,0) AS FlagC2,isnull(FlagC3,0) AS FlagC3,isnull(FlagC4,0) AS FlagC4,isnull(FlagC5,0) AS FlagC5,isnull(FlagC6,0) AS FlagC6
INTO #CONSOLIDADO_MH
FROM #ESTRUCTURAFINAL A
LEFT JOIN #LIDERES B ON A.CodLider=B.CodLider
LEFT JOIN #MyC_PUP C ON A.PKEbelista=C.PKEbelista AND A.ANIOCAMPANAPROCESO=C.ANIOCAMPANAPROCESO
LEFT JOIN #MyC_P$P K ON A.PKEbelista=K.PKEbelista AND A.ANIOCAMPANAPROCESO=K.ANIOCAMPANAPROCESO
LEFT JOIN #FINALCyR_PUP D ON A.PKEbelista=D.PKEbelista AND A.ANIOCAMPANAPROCESO=D.ANIOCAMPANAPROCESO
LEFT JOIN #FINALCyR_P$P L ON A.PKEbelista=L.PKEbelista AND A.ANIOCAMPANAPROCESO=L.ANIOCAMPANAPROCESO
LEFT JOIN #PIVOTBD_PUP G ON A.PKEbelista=G.PKEbelista AND A.ANIOCAMPANAPROCESO=G.ANIOCAMPANAPROCESO
LEFT JOIN #PIVOTBD_P$P M ON A.PKEbelista=M.PKEbelista AND A.ANIOCAMPANAPROCESO=M.ANIOCAMPANAPROCESO
LEFT JOIN #tempoCategoria_PUP F ON A.PKEbelista=F.PKEbelista AND A.ANIOCAMPANAPROCESO=F.ANIOCAMPANAPROCESO
LEFT JOIN #tempoCategoria_P$P N ON A.PKEbelista=N.PKEbelista AND A.ANIOCAMPANAPROCESO=N.ANIOCAMPANAPROCESO
INNER JOIN #segmentoc7 I ON A.pkebelista = I.pkebelista 
INNER JOIN #DetallePedidoCN J ON A.pkebelista = J.pkebelista

-- 201713, consultoras: 3068, registros total: 18408
-- 201714, consultoras: 2763, registros total: 16578
-- 201715, consultoras: 2576, registros total: 15456
-- 201716, consultoras: 2463, registros total: 14778

-- 201717, consultoras: 2761, registros total: 16566
-- 201718, consultoras: 2804, registros total: 16824
-- 201801, consultoras: 3084, registros total: 18504

-- Validación:
/*
select count(1) from #CONSULTORAS
select count(1), pkebelista from #ESTRUCTURAFINAL group by pkebelista order by 1 asc
select count(1), pkebelista from #CONSOLIDADO_MH group by pkebelista order by 1 asc

select * from #CONSOLIDADO_MH order by pkebelista,aniocampanaproceso 
*/

-- Insertando Cosechas

select * 
into DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1
from #CONSOLIDADO_MH

insert into DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1
select *
from #CONSOLIDADO_MH

/*
SELECT count(1), pkebelista
FROM #CONSOLIDADO_MH group by pkebelista order by 1 asc

select * from #ConteoCategorias where pkebelista=676531

select * FROM #FVTAPROEBECAMC01 A LEFT JOIN #DPRODUCTO3 B on A.pkproducto = B.pkproducto

select count(1), pkebelista from #PIVOTBD_PUP group by pkebelista order by 1 asc
select count(1), pkebelista from #ESTRUCTURAFINAL group by pkebelista order by 1 asc
select count(1), pkebelista from #CONSOLIDADO_MH group by pkebelista order by 1 asc

select * from #ESTRUCTURAFINAL where pkebelista=675853 order by aniocampanaproceso

select pkebelista, desnivel, RANK() OVER(ORDER BY PKEBELISTA)
 from #CONSOLIDADO_MH 
 group by pkebelista, desnivel
 order by pkebelista
*/

select count(1) from #CONSULTORAS
select count(1) from #CONSOLIDADO_MH

select count(1) from DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1

select * from DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1

drop table DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1
select distinct campinicio, campfin, campexito from DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1

select count(1), pkebelista from DATAMARTANALITICO.dbo.MC_ConsolidadoNuevas1 group by pkebelista order by 1 asc 


select * from #LIDERES
