package types_pkg;

    // Статусы операций
    typedef enum logic [1:0] {
        ST_OK    = 2'b00,
        ST_ERR   = 2'b01,
        ST_BUSY  = 2'b10,
        ST_RESET = 2'b11
    } status_e;

    // Что ещё захочешь — на твоё усмотрение
    
endpackage