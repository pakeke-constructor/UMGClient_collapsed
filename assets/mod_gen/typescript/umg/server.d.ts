/** @NoSelfInFile */

export {};

/** @NoSelf */
interface ServerEventHandler<T> {
    handler(player: PlayerObject, ...args: unknown[]): void;
    arguments: ((x: any, player: PlayerObject) => number)[]
}


/** @noSelf **/
declare interface _serverAPI {
    on(event: string, handler: ServerEventHandler): void;
    broadcast(event: string, ...args: any[]): void;
    unicast(player: PlayerObject, event: string, ...args: any[]): void;
    lazyBroadcast(event: string, ...args: any[]): void;
    lazyUnicast(player: PlayerObject, event: string, ...args: any[]): void;

    readonly entities: LuaMap<string, (...args: any[]) => Entity>;
}

declare global {
    const server: _serverAPI | undefined;
}
