//
//  AppDelegate.m
//  rGKrellMosx
//
//  Created by Luis Palacios on 28/08/13.
//  Copyright (c) 2013 Luis Palacios. All rights reserved.
//

#import "AppDelegate.h"

NSString *const LPPrefsKey_Hostname         = @"LPPrefsKey_Hostname";
NSString *const LPPrefsKey_Port             = @"LPPrefsKey_Port";
NSString *const LPPrefsKey_Username         = @"LPPrefsKey_Username";
NSString *const LPPrefsKey_Comando          = @"LPPrefsKey_Comando";
NSString *const LPPrefsKey_CloseOnLaunch    = @"LPPrefsKey_CloseOnLaunch";


@implementation AppDelegate
@synthesize hostname = ivHostname;
@synthesize port = ivPort;
@synthesize username = ivUsername;
@synthesize comando = ivComando;
@synthesize shellComando = ivShellComando;
@synthesize outputLog = ivOutputLog;
@synthesize outputLogString = ivOutputLogString;

//------------------------------------------------------

/** Inicio de la aplicación
 *
 *
 *  Voy a trabajar con las "preference defaults" y el fichero de trabajo será:
 *  /Users/<usuario>/Library/Preferences/Parchis.rGKrellMosx.plist
 *
 *  Para leerlas desde la línea de comandos:
 *  defaults read Parchis.rGKrellMosx.plist
 *
 */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [[self hostname] setDelegate:self];
    // Insert code here to initialize your application
    [self updateShellComando];
    
    // Verifico los defaults.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *def_Hostname = [defaults stringForKey:LPPrefsKey_Hostname];
    NSString *def_Port = [defaults stringForKey:LPPrefsKey_Port];
    NSString *def_Username = [defaults stringForKey:LPPrefsKey_Username];
    NSString *def_Comando = [defaults stringForKey:LPPrefsKey_Comando];
    if ( !def_Hostname && !def_Port && !def_Username && !def_Comando )
        [self resetToDefaults:nil];
}
/** @brief Evitar que se cierre la aplicación al cerrar su última ventana
 *
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}


//------------------------------------------------------

/** Actualizar los datos de entrada de la ventana
 *
 */
- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self updateShellComando];
}

/** Actualizar el comando que se ejecutará
 *
 */
- (void) updateShellComando
{
    NSString *shellComando = [NSString stringWithFormat:@"ssh -X -p %@ -l %@ %@ %@",
                              [[self port] stringValue],
                              [[self username] stringValue],
                              [[self hostname] stringValue],
                              [[self comando] stringValue]
                         ];
    [[self shellComando]setStringValue:shellComando];
}

/** Lanzar la ejecución del comando
 *
 */
- (IBAction)doIt:(id)sender {

    // Limpio el output Log
    [[self outputLog] setString:@""];

    // Ejecutar el comando en el background
    [self performSelectorInBackground:@selector(backgroundCommand) withObject:nil];

    return;
    
    // Salgo de la aplicación
    // [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (IBAction)resetToDefaults:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"servidor.dominio.com" forKey:LPPrefsKey_Hostname ];
    [defaults setObject:@"22" forKey:LPPrefsKey_Port ];
    [defaults setObject:@"user1" forKey:LPPrefsKey_Username ];
    [defaults setObject:@"gkrellm" forKey:LPPrefsKey_Comando ];
}



//------------------------------------------------------

/** @brief MAIN THREAD: Terminó la tarea
 *
 *  Al terinnar la tarea en el background se invoca a backgroundCommandDidTerminate: que a su 
 *  vez llama a este método para que desde aquí se actaulice el UI.
 *
 */
-(void) mainThreadCommandDidTerminate
{
    // NSLog(@"[%@ %@] El comando ha terminado", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    // Muestro en pantalla la salida del comando
    [[self outputLog]setString:[self outputLogString]];
    
}


//------------------------------------------------------

/** @brief BACKGROUND: Ejecutar un comando.
 *
 *  Esta tarea se ejecuta en el background porque se llama desde "performSelectorInBackground..."
 */
-(void) backgroundCommand
{
    // Log
    // NSLog(@"[%@ %@] Inicio la ejecución del comando", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    // Recupero el comando a ejecutar.
    NSString *commandToRun = [[self shellComando] stringValue ];
    
    // Creo una tarea con su argumento
    // NSTask *task = [[NSTask alloc] init];
    // [self setTask:[[NSTask alloc] init]];
    NSTask *task = [[NSTask alloc]init];

    [task setLaunchPath: @"/bin/sh"];
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    [task setArguments: arguments];

    // Preparo el PIPE para capturar standard input,output,error
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    [task setStandardInput:[NSPipe pipe]]; //The magic line that keeps your log where it belongs

    // Preparo el file handle donde recibo dicho output
    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    // Lanzo el comando
    [task launch];
    
    // Si así se indica, cierro la ventana
    BOOL isCloseOnLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:LPPrefsKey_CloseOnLaunch];
    if ( isCloseOnLaunch ) {
        // Cierro la ventana, pero OJO que "NO" cierro el programa
        [[self window] close];
    }
    
    // Capturo la salida del comando
    NSData *data;
    data = [file readDataToEndOfFile];
    
    // Convierto la salida del comando a UTF8
    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //NSLog(@"output: %@", output);

    // Se ejecuta en el background, no hacer un update del UI desde aqui
    // NSLog(@"[%@ %@] Fin de la tarea en el background", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    // Llamo a un método en el mainThread para actualizar el UI desde ahí
    [self setOutputLogString:output];
    [self performSelectorOnMainThread:@selector(mainThreadCommandDidTerminate) withObject:nil waitUntilDone:NO];

    // Terminó, libero el task
    [task release];

}

/** @brief BACKGROUND: Ejecutar cuando termina la tarea que se ha ejecutado en el background
 *
 *  Desde aquí NO se debe actualizar el UI. Solo hay que llamar a un método en el mainThread
 *  para que sea desde ahí desde donde se actualice el UI.
 */
- (void) backgroundCommandDidTerminate:(NSNotification *)notification {

    // Se ejecuta en el background, no hacer un update del UI desde aqui
    // NSLog(@"[%@ %@] Find de la tarea en el background", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    // Llamo a un método en el mainThread para actualizar el UI desde ahí
    [self performSelectorOnMainThread:@selector(mainThreadCommandDidTerminate) withObject:nil waitUntilDone:NO];
}

/** @brief dormir el número de segundos indicado
 *
 */
-(void) duerme:(NSInteger)segundos
{
    
    // SLEEP (Incluir #include <unistd.h>)
    struct timespec sleep_interval;
    sleep_interval.tv_sec = segundos;      // 1 = 1 segundo
    sleep_interval.tv_nsec = 0;     // 1000 = 1 microsecond. 1000000 = 1 milisegundo.
    nanosleep( &sleep_interval, 0 );
}

//------------------------------------------------------

@end
