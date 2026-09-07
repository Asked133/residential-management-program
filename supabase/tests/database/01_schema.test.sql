BEGIN;

SELECT plan(2);

-- Test 1: Verificar que existe la tabla de usuarios
SELECT has_table('public', 'usuarios', 'La tabla usuarios debe existir');

-- Test 2: Verificar que existe la tabla de viviendas
SELECT has_table('public', 'viviendas', 'La tabla viviendas debe existir');

SELECT * FROM finish();

ROLLBACK;
