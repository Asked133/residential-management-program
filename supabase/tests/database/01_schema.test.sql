BEGIN;

SELECT plan(3);

-- Test 1: Verificar que existe la tabla de usuarios
SELECT has_table('public', 'usuarios', 'La tabla usuarios debe existir');

-- Test 2: Verificar que existe la tabla de viviendas
SELECT has_table('public', 'viviendas', 'La tabla viviendas debe existir');

-- Test 3: Verificar que existe la tabla de condominios
SELECT has_table('public', 'condominios', 'La tabla condominios debe existir');

SELECT * FROM finish();

ROLLBACK;
