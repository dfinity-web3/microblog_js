import Time "mo:base/Time";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Text "mo:base/Text";


actor {
  public type Message = {
    text: Text;
    time: Time.Time;
    author: Text;
  };
  public type AuthorPrincipal = {
    author: Text;
    principalId: Text;
  };

  public type Microblog = actor {
    follow: shared(Principal) -> async ();                        ///添加关注对象
    follows:shared query () -> async [Principal];                 ///返回关注对象
    post: shared (Text,Text) -> async ();                         ///发布新消息
    posts_t : shared query (Time.Time) -> async [Message];        ///返回 某个时间之后 发布的消息
    posts : shared query () -> async [Message];                   ///返回所有发布的消息
    get_followed_authors : shared () -> async [AuthorPrincipal];
    timeline_t : shared (Time.Time) -> async [Message];           ///返回所有关注对象 某个时间之后 发布的消息 
    timeline : shared () -> async [Message];                      ///返回所有关注对象  发布的消息 
    set_name : shared (Text) -> async ();
    get_name : shared query () -> async (?Text);
    get_posts_by_author : shared (Text) -> async [Message];
  };
  var followed : List.List<Principal> = List.nil();

  public shared func follow(id: Principal):async () {
    followed := List.push(id,followed);
  };
  public shared query func follows() : async [Principal]{
    List.toArray(followed)
  };

  private var author: ?Text = null;

  var messages : List.List<Message> = List.nil();
  
  public shared func set_name(name: Text) : async() {
    author := ?name;
  };
  public shared query func get_name(): async ?Text {
    return author;
  };

  public shared (msg) func post(otp:Text,text: Text): async() {
    assert(otp == "123456");
    let newMessage = {
      text = text;
      time = Time.now();
      author = switch (author) {
        case null { "Unknown" };
        case (?a) { a };
      };
    };
    messages := List.push(newMessage, messages);
  };

  public shared query func posts_t(since: Time.Time): async [Message] {
    let filteredMessages = List.filter(messages, func(m: Message): Bool {
        m.time >= since
    });
    List.toArray(filteredMessages)
  };

  public shared query func posts() :async [Message]{
    List.toArray(messages)
  };

  public shared func get_posts_by_author(principalIdText: Text) : async [Message] {
    let canister: Microblog = actor(principalIdText);
    let posts = await canister.posts();
    return posts;
  };

  public shared func get_followed_authors() : async [AuthorPrincipal] {
    var authors: [AuthorPrincipal] = [];
    for (id in Iter.fromList(followed)) {
        let canister: Microblog = actor(Principal.toText(id));
        let authorName = await canister.get_name();
        let authorPrincipal = {
            author = switch (authorName) {
                case null { "Unknown" };
                case (?name) { name };
            };
            principalId = Principal.toText(id);
        };
        authors := Array.append(authors, [authorPrincipal]);
    };
    return authors;
  };

  public shared func timeline_t(since: Time.Time): async [Message] {
    var all: List.List<Message> = List.nil();
    
    for (id in Iter.fromList(followed)) {
        let canister: Microblog = actor(Principal.toText(id));
        let msgs = await canister.posts_t(since);
        for (msg in Iter.fromArray(msgs)) {
            all := List.push(msg, all);
        }
    };
    let filteredMessages = List.filter(all, func(m: Message): Bool {
        m.time >= since
    });
    List.toArray(filteredMessages)
  };
  public shared func timeline(): async [Message] {
    var all: List.List<Message> = List.nil();
    
    for (id in Iter.fromList(followed)) {
        let canister: Microblog = actor(Principal.toText(id));
        let msgs = await canister.posts(); // 使用不带 since 参数的 posts 函数
        for (msg in Iter.fromArray(msgs)) {
            all := List.push(msg, all);
        }
    };
    List.toArray(all)
  };
};

