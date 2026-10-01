require 'minitest/autorun'
require 'open3'

class Bug004JsConcurrencyTest < Minitest::Test
  def test_js_concurrency_abort_bug
    # Buat berkas JS untuk mengetes logika doFetch di api.js
    js_code = <<~JS
      let activeController = null;
      
      const logs = [];
      function doFetch(id) {
        return new Promise((resolve, reject) => {
          if (activeController) {
            logs.push('aborted ' + activeController.id);
            activeController.abort();
          }
          
          activeController = new AbortController();
          activeController.id = id;
          const myController = activeController;
          
          setTimeout(() => {
            try {
              if (myController.signal.aborted) {
                throw new Error('AbortError');
              }
              logs.push('resolved ' + id);
            } catch(e) {
              logs.push('caught ' + id);
            } finally {
              activeController = null;
            }
          }, 10);
        });
      }
      
      doFetch(1);
      doFetch(2);
      
      setTimeout(() => {
        doFetch(3);
      }, 15);
      
      setTimeout(() => {
        console.log(logs.join(', '));
      }, 50);
    JS
    
    out, _, _ = Open3.capture3("node", "-e", js_code)
    # The expected bug behavior: 
    # 1 is aborted by 2.
    # 1's timeout runs, catches AbortError (or whatever), and sets activeController = null (which was holding 2!).
    # Then 3 runs. It sees activeController is null (because 1 cleared it!). So it doesn't abort 2!
    # 2 and 3 resolve!
    # Wait, in the JS code above, abort is triggered, but fetch aborts IMMEDIATELY. Our setTimeout doesn't exactly simulate fetch abort.
    # But it's true: the finally block of the aborted fetch clears the activeController that belongs to the NEW fetch!
    
    # We can just manually check if api.js has this exact flaw via string match.
    api_js = File.read(File.expand_path('../../../public/js/api.js', __dir__))
    
    # Check if activeController = null is unconditionally executed in finally
    
    # If the bug exists, we fail the test to show it's RED.
    # Actually, the test should fail to be a valid RED test.
    # Since the bug exists, we assert the opposite to make it fail.
    refute_match /finally\s*\{\s*activeController = null;\s*\}/, api_js, "Melanggar I5: Concurrency race condition terdeteksi di api.js dimana finally membersihkan activeController milik request yang lebih baru."
  end
end
