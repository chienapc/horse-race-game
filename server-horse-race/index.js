const io = require("socket.io")(3000, {
  cors: { origin: "*" },
  pingInterval: 2000, // Gửi ping kiểm tra mỗi 2 giây
  pingTimeout: 5000   // Nếu không phản hồi trong 5 giây -> Ép ngắt kết nối
});

// Lưu trữ danh sách người chơi tạm thời (Session-based)
const rooms = {}; 

io.on("connection", (socket) => {
  console.log("Kết nối mới: " + socket.id);

  socket.on("join_room", (data) => {
    const { roomId, nickname } = data;

    // Khởi tạo phòng nếu chưa có
    if (!rooms[roomId]) rooms[roomId] = [];

    // Xóa kết nối cũ nếu người chơi trùng tên HOẶC trùng session (phòng lách luật đổi tên trên cùng 1 máy)
    rooms[roomId] = rooms[roomId].filter(u => u.name !== nickname && u.id !== socket.id);

    // Kiểm tra giới hạn tối đa 6 người
    if (rooms[roomId].length >= 6) {
      socket.emit("room_full", { message: "Phòng đua này đã đầy (tối đa 6 người)!" });
      return;
    }

    socket.join(roomId);

    // Thêm người chơi vào danh sách của phòng
    const newUser = { id: socket.id, name: nickname, isHost: rooms[roomId].length === 0, betAmount: 0, selectedHorse: null };
    rooms[roomId].push(newUser);

    console.log(`${nickname} đã vào phòng ${roomId} với vai trò ${newUser.isHost ? 'Host' : 'Client'}`);

    // Gửi xác nhận cho người vừa vào
    socket.emit("room_joined", { roomId, role: newUser.isHost ? "Host" : "Client" });

    // QUAN TRỌNG: Gửi danh sách người chơi cho TẤT CẢ mọi người trong phòng này
    io.to(roomId).emit("update_player_list", rooms[roomId]);
  });

  socket.on("start_countdown", (data) => {
    io.to(data.roomId).emit("start_countdown", data);
  });

  socket.on("send_pos", (data) => {
    // data.room là roomId, data.positions là mảng vị trí
    socket.to(data.room).emit("update_pos", data.positions); // Gửi cho mọi người trừ người gửi
  });

  socket.on("finish_race", (data) => {
    io.to(data.roomId).emit("finish_race", data);
  });

  socket.on("reset_race", (data) => {
    const room = rooms[data.roomId];
    if (room) {
      room.pot = 0;
      room.forEach(u => {
        u.betAmount = 0;
        u.selectedHorse = null;
      });
      io.to(data.roomId).emit("update_pot", { totalPot: 0, players: room });
    }
    io.to(data.roomId).emit("reset_race", data);
  });

  socket.on("place_bet", (data) => {
    const { roomId, betAmount, horseIndex } = data;
    if (rooms[roomId]) {
      const room = rooms[roomId];
      if (typeof room.pot === 'undefined') room.pot = 0;
      room.pot += betAmount;

      const user = room.find(u => u.id === socket.id);
      if (user) {
        user.betAmount = betAmount;
        user.selectedHorse = horseIndex;
      }

      io.to(roomId).emit("update_pot", { totalPot: room.pot, players: room });
    }
  });

  socket.on("start_session", (data) => {
    // Host ấn bắt đầu -> Báo cho toàn phòng vào màn hình đua
    io.to(data.roomId).emit("navigate_to_race", data);
  });

  // Hàm hỗ trợ xóa người chơi và chuyển quyền chủ phòng
  const removeUserFromRoom = (socketId, roomId) => {
    if (rooms[roomId]) {
      rooms[roomId] = rooms[roomId].filter(user => user.id !== socketId);
      
      if (rooms[roomId].length === 0) {
        delete rooms[roomId]; // Xóa phòng nếu trống
      } else {
        // Chuyển quyền Chủ phòng (Host) nếu Host cũ vừa thoát
        const hasHost = rooms[roomId].some(u => u.isHost);
        if (!hasHost && rooms[roomId].length > 0) {
          rooms[roomId][0].isHost = true;
          // Thông báo cập nhật vai trò cho Host mới (nếu cần xử lý riêng)
        }
        io.to(roomId).emit("update_player_list", rooms[roomId]);
      }
    }
  };

  socket.on("leave_room", (data) => {
    if (data && data.roomId) {
      socket.leave(data.roomId);
      removeUserFromRoom(socket.id, data.roomId);
    }
  });

  socket.on("disconnect", () => {
    // Xử lý xóa người chơi khỏi danh sách khi thoát
    for (const roomId in rooms) {
      removeUserFromRoom(socket.id, roomId);
    }
    console.log("Một người chơi đã thoát.");
  });
});