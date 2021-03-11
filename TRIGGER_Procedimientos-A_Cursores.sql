/*Trigger que no permita crear una reservacion para un cliente si tiene mas de 3 reservaciones pasadas con una calificacion menor o igual que 4.*/

/*TRIGGER*/


---------------------------------------------
create or replace function tg_reserva() returns trigger
as
$tg_reserva$
    declare
	malas_calificaciones int;
begin
		SELECT count(*) into malas_calificaciones FROM reserva_habitacion
		where reserva_habitacion.cli_id = NEW.cli_id and reserva_habitacion.hd_calificaccion_em <= 4;

        if(malas_calificaciones>=3) then
		raise exception 'No se puede realizar una reserva para el cliente porque posee 3 o mas calificaciones negativas';
		end if;
        return new;
end;
$tg_reserva$
language plpgsql;

create trigger tg_reserva before insert OR UPDATE
on reserva_habitacion for each row
execute procedure tg_reserva();
--------------------------------------------------------------------------

--------------------------------------------------------------------------------------

/*Cursor que muestre las ganancias totales generadas por cada una de la habitaciones y el tipo de habitacion.*/
/*CURSOR*/
do $$
declare
	tabla Record;
	cur_ganancia_habitacion Cursor for SELECT RESERVA_HABITACION.HD_N_HABITACION,HABITACION.ID_DESCRICCION_HABITACION,SUM(FACTURA.FAC_TOTAL) as total  FROM FACTURA
	INNER JOIN DETALLE_FACTURA ON DETALLE_FACTURA.FACTURA_ID = FACTURA.FACTURA_ID
	INNER JOIN RESERVA_HABITACION ON RESERVA_HABITACION.HD_ID = DETALLE_FACTURA.HD_ID
	INNER JOIN HABITACION ON HABITACION.ID_HABITACION = RESERVA_HABITACION.ID_HABITACION
	GROUP BY (RESERVA_HABITACION.HD_N_HABITACION,habitacion.id_descriccion_habitacion);
	begin
	for tabla in cur_ganancia_habitacion loop
	Raise notice 'Nro Habitacion: %,Tipo: %,Ganancias Generadas: %',tabla.HD_N_HABITACION,tabla.ID_DESCRICCION_HABITACION,tabla.total;
	end loop;
end $$
language 'plpgsql';


/*Un procedimiento almacenado que reciba como parametro la cedula de un empleado y que devuelva las ganacias generadas por la suma totala de todas sus facturas por tipo de habitacion.
*/
/*PROCEDIMIENTO ALMACENADO*/
create or replace function obtener_ventas_totales( cedula_empleado integer)
RETURNS TABLE (empleado_nombre varchar,
	empleado_apellido varchar,
	tipo_habitacion varchar,	
	ingresos_generados numeric)
as $BODY$
begin
	RETURN QUERY
	SELECT EMPLEADO.EM_NOMBRE, EMPLEADO.EM_APELLIDO, HABITACION.ID_DESCRICCION_HABITACION, SUM(FACTURA.FAC_TOTAL)TOTAL_VENTAS FROM EMPLEADO
	INNER JOIN FACTURA ON FACTURA.EM_ID = EMPLEADO.EM_ID
	INNER JOIN DETALLE_FACTURA ON DETALLE_FACTURA.FACTURA_ID = FACTURA.FACTURA_ID
	INNER JOIN RESERVA_HABITACION ON RESERVA_HABITACION.HD_ID = DETALLE_FACTURA.HD_ID
	INNER JOIN HABITACION ON HABITACION.ID_HABITACION = RESERVA_HABITACION.ID_HABITACION
	WHERE EMPLEADO.EM_CEDULA = cedula_empleado
	GROUP BY(EMPLEADO.EM_NOMBRE, EMPLEADO.EM_APELLIDO, HABITACION.ID_DESCRICCION_HABITACION);
end
$BODY$ language plpgsql;

/*IReport de una factura para una reservación*/
SELECT FACTURA.FACTURA_ID, FACTURA.FAC_TOTAL, FACTURA.FACTURA_FECHA_EMICION, RESERVA_HABITACION.HD_FECHA_INGRESO, RESERVA_HABITACION.HD_FECHA_SALIDA,
RESERVA_HABITACION.HD_TIEMPO,RESERVA_HABITACION.HD_N_HABITACION, HABITACION.ID_DESCRICCION_HABITACION,HABITACION.ID_PRECIO_HABITACIO,CLIENTE.CLI_NOMBRE,CLIENTE.CLI_APELLIDO,CLIENTE.CLI_CEDULA,
MOTEL.MOTEL_NOMBRE,MOTEL.MOTEL_DIRECCION,MOTEL.MOTEL_TELEFONO, SERVICIO.SP_DESCRIPCION_SERVICIO, SERVICIO.SP_PRECIO, SERVICIO.SP_DESCRICCION_FORMA_COBRO
FROM FACTURA
	INNER JOIN DETALLE_FACTURA ON DETALLE_FACTURA.FACTURA_ID = FACTURA.FACTURA_ID
	INNER JOIN RESERVA_HABITACION ON RESERVA_HABITACION.HD_ID = DETALLE_FACTURA.HD_ID
	INNER JOIN HABITACION ON HABITACION.ID_HABITACION = RESERVA_HABITACION.ID_HABITACION
	INNER JOIN CLIENTE ON CLIENTE.CLI_ID = RESERVA_HABITACION.CLI_ID
	INNER JOIN MOTEL ON MOTEL.MOT_ID = FACTURA.MOT_ID
	INNER JOIN SERVICIO ON SERVICIO.SP_ID = DETALLE_FACTURA.SP_ID
WHERE FACTURA.FACTURA_ID =$P{Factura_id}
